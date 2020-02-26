import Foundation

class AbsentService {
  var cache: (Date, [Absent])?
  let authorizer = Authorizer()
  let favSorter = FavoriteSorter()
  
  private let absentURL = Bundle.main.infoDictionary!["ABSENT_URL"]! as! String
    
  func getAbsent(allowUIAuth: Bool, callback: @escaping (([Absent]) -> Void)) {
    if let cache = cache {
      if Date().timeIntervalSince(cache.0) < 3600 {
        callback(cache.1)
        return
      }
    }
    guard let token = authorizer.token else {
      self.authorizer.authorize(allowUI: allowUIAuth) {
        self.getAbsent(allowUIAuth: allowUIAuth, callback: callback)
      }
      return
    }
    
    let headers = [
      "Content-Type": "application/json",
      "Authorization": token
    ]
    
    let request = NSMutableURLRequest(url: NSURL(string: absentURL)! as URL,
                                      cachePolicy: .useProtocolCachePolicy,
                                      timeoutInterval: 10.0)
    request.httpMethod = "GET"
    request.allHTTPHeaderFields = headers
    
    let session = URLSession.shared
    let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
      if (error != nil || (response as? HTTPURLResponse)?.statusCode != 200) {
        if ((response as? HTTPURLResponse)?.statusCode ?? 501 >= 500) {
          return
        }
        self.authorizer.authorize(allowUI: allowUIAuth) {
          self.getAbsent(allowUIAuth: allowUIAuth, callback: callback)
        }
      } else {
        var absent = try! JSONDecoder().decode([Absent].self, from: data!)
        absent = self.favSorter.sort(list: absent)
        self.cache = (Date(), absent)
        DispatchQueue.main.sync{
          callback(absent)
        }
      }
    })
    
    dataTask.resume()
  }
}

enum AbsentType: String, Codable {
  case Business = "Business Trip", WFH = "Remote", Training = "Training", other
  var string: String {
    get {
      switch self {
      case .other:
        return "Out of office"
      default:
        return rawValue
      }
    }
  }
  
}

struct Absent: Codable {
  let name: String
  let type: AbsentType
  let until: Date
  let approved: Bool
  
  enum CodingKeys: String, CodingKey {
    case name
    case type
    case until
    case approved
  }
  
  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    name = try values.decode(String.self, forKey: .name)
    approved = try values.decode(Bool.self, forKey: .approved)
    type = AbsentType(rawValue: try values.decode(String.self, forKey: .type)) ?? .other
    let stringDate = try values.decode(String.self, forKey: .until)
    let RFC3339DateFormatter = DateFormatter()
    RFC3339DateFormatter.locale = Locale(identifier: "en_US_POSIX")
    RFC3339DateFormatter.dateFormat = "yyyy-MM-dd"
    until = RFC3339DateFormatter.date(from: stringDate)!
    
  }
}
