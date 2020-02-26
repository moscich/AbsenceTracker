import Foundation

class FavoriteSorter {
  
  var favorites = [String]()
  
  
  init() {
    if let dir = FileManager.default.urls(for: .applicationDirectory, in: .userDomainMask).first {
      let plist = NSDictionary(contentsOf: dir.appendingPathComponent("preferences.plist"))
      favorites = (plist?["Favorites"] as? [String] ?? []).reversed()
    }
  }
  
  func sort(list: [Absent]) -> [Absent] {
    var mutList = list
    favorites.forEach { fav in
      if let index = (mutList.firstIndex { absent -> Bool in
        absent.name == fav
        }) {
        let elem = mutList[index]
        mutList.remove(at: index)
        mutList.insert(elem, at: 0)
      }
    }
    return mutList
  }
}
