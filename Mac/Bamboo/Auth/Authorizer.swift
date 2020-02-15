import Foundation
import WebKit
import KeychainSwift
import JWTDecode

class Authorizer {
  var window: NSWindow!
  var callback: (() -> Void)?
  var token: String? {
    get {
      guard let token = storedToken,
        let expiresAt = try? decode(jwt: token).expiresAt,
        expiresAt.timeIntervalSince(Date()) > 60
        else { return nil }
      return token
    }
  }
  private var storedToken: String?
  
  private var refreshTokenId = Bundle.main.infoDictionary!["REFRESH_TOKEN_ID"]! as! String
  private var cognitoURL = Bundle.main.infoDictionary!["COGNITO_URL"]! as! String
  private var cognitoClientId = Bundle.main.infoDictionary!["COGNITO_CLIENT_ID"]! as! String
  
  func authorize(allowUI: Bool, callback: @escaping () -> Void) {
    self.callback = callback
    
    if let refreshToken = KeychainSwift().get(refreshTokenId) {
      refresh(token: refreshToken)
      return
    }
    
    guard allowUI == true else { return }
    
    NotificationCenter.default.addObserver(forName: Notification.Name("auth-code"), object: nil, queue: nil) {
      guard let authCode = $0.object as? String else { return }
      self.auth(code: authCode)
    }
    
    let frame = CCNStatusItem.sharedInstance()?.statusItem.button?.window?.frame ?? .zero
    
    window = NSWindow(contentRect: CGRect(x: frame.origin.x - 250, y: frame.origin.y - 550, width: 500, height: 500), styleMask: .titled, backing: .buffered, defer: false)
    window.styleMask = window.styleMask.union(.closable)
    window.title = "Absent authorize"
    window.makeKeyAndOrderFront(nil)
    
    let webView = WKWebView(frame: .zero)
    window.contentView?.addSubview(webView)
    webView.translatesAutoresizingMaskIntoConstraints = false
    guard let content = window.contentView else { return }
    NSLayoutConstraint.activate([
      webView.topAnchor.constraint(equalTo: content.topAnchor),
      webView.bottomAnchor.constraint(equalTo: content.bottomAnchor),
      webView.leadingAnchor.constraint(equalTo: content.leadingAnchor),
      webView.trailingAnchor.constraint(equalTo: content.trailingAnchor),
    ])
    
    webView.load(URLRequest(url: URL(string: "\(cognitoURL)/login?client_id=\(cognitoClientId)&response_type=code&scope=openid&redirect_uri=bambooapp://test.me")!))
    
  }
  
  func auth(code: String) {
    let headers = [
      "Content-Type": "application/x-www-form-urlencoded"
    ]
    
    let postData = NSMutableData(data: "grant_type=authorization_code&code=\(code)&client_id=\(cognitoClientId)&redirect_uri=bambooapp://test.me".data(using: String.Encoding.utf8)!)
    let request = NSMutableURLRequest(url: NSURL(string: "\(cognitoURL)/oauth2/token")! as URL,
                                      cachePolicy: .useProtocolCachePolicy,
                                      timeoutInterval: 10.0)
    request.httpMethod = "POST"
    request.allHTTPHeaderFields = headers
    request.httpBody = postData as Data
    
    let session = URLSession.shared
    let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
      if (error != nil) {
      } else {
        
        do {
          let x = try JSONDecoder().decode(AuthResponse.self, from: data!)
          let keychain = KeychainSwift()
          self.storedToken = x.idToken
          if let refreshToken = x.refreshToken {
            keychain.set(refreshToken, forKey: self.refreshTokenId)
          }
          
        } catch {
          print(error)
        }
        
        DispatchQueue.main.sync{
          self.callback?()
          self.window.close()
        }
        
        
      }
    })
    
    dataTask.resume()
  }
  
  func refresh(token: String) {
    let headers = [
      "Content-Type": "application/x-www-form-urlencoded"
    ]
    
    let postData = NSMutableData(data: "grant_type=refresh_token&refresh_token=\(token)&client_id=\(cognitoClientId)&redirect_uri=bambooapp://test.me".data(using: String.Encoding.utf8)!)
    let request = NSMutableURLRequest(url: NSURL(string: "\(cognitoURL)/oauth2/token")! as URL,
                                      cachePolicy: .useProtocolCachePolicy,
                                      timeoutInterval: 10.0)
    request.httpMethod = "POST"
    request.allHTTPHeaderFields = headers
    request.httpBody = postData as Data
    
    let session = URLSession.shared
    let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
      if (error != nil) {
      } else {
        do {
          let x = try JSONDecoder().decode(AuthResponse.self, from: data!)
          let keychain = KeychainSwift()
          self.storedToken = x.idToken
          keychain.set(token, forKey: self.refreshTokenId)
          
        } catch {
        }
        
        DispatchQueue.main.sync{
          self.callback?()
        }
        
        
      }
    })
    
    dataTask.resume()
  }
  
}
