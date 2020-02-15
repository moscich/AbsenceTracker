import Cocoa
import AppKit
import HotKey

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  var window: NSWindow!
  let vc = SearchAbsentViewController()
  let hotKey = HotKey(key: .b, modifiers: [.command, .shift])
  
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    hotKey.keyDownHandler = {
      CCNStatusItem.sharedInstance().showWindow()
    }
    let aem = NSAppleEventManager.shared();
    aem.setEventHandler(self, andSelector: #selector(AppDelegate.handleGetURLEvent(event:replyEvent:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
    
    vc.preferredContentSize = CGSize(width: 320, height: 200)
    CCNStatusItem.sharedInstance().present(with: NSImage(named: NSImage.Name("icon")), contentViewController: vc)
  }
  
  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }
  
  @objc func handleGetURLEvent(event: NSAppleEventDescriptor, replyEvent: NSAppleEventDescriptor) {
    
    let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue!
    let comps = URLComponents(string: urlString!)
    let x = comps?.queryItems
    let code = x!.first(where: {$0.name == "code"})!.value!
    
    NotificationCenter.default.post(name: Notification.Name("auth-code"), object: code)
  }
  
}

