import Foundation
import AppKit

class SearchAbsentViewController: NSViewController {
  let search = NSSearchField()
  let tableView = NSTableView()
  let service = AbsentService()
  var absent:[Absent] = []
  var filtered:[Absent] = []
  let RFC3339DateFormatter = DateFormatter()
    
  init() {
    super.init(nibName: nil, bundle: nil)
    RFC3339DateFormatter.locale = Locale(identifier: "en_US_POSIX")
    RFC3339DateFormatter.dateFormat = "yyyy-MM-dd"
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func loadView() {
    view = NSView(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
    let scroll = NSScrollView()
    let killButton = NSButton()
    killButton.title = "Turn off"
    killButton.action = #selector(turnOff)
    let repoButton = NSButton()
    repoButton.title = "Github"
    repoButton.action = #selector(github)
    view.addSubview(scroll)
    view.addSubview(search)
    view.addSubview(killButton)
    view.addSubview(repoButton)
    scroll.documentView = tableView
    scroll.hasVerticalScroller = true
    
    scroll.translatesAutoresizingMaskIntoConstraints = false
    search.translatesAutoresizingMaskIntoConstraints = false
    tableView.translatesAutoresizingMaskIntoConstraints = false
    killButton.translatesAutoresizingMaskIntoConstraints = false
    repoButton.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      search.topAnchor.constraint(equalTo: view.topAnchor),
      search.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      search.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scroll.topAnchor.constraint(equalTo: search.bottomAnchor),
      scroll.bottomAnchor.constraint(equalTo: killButton.topAnchor),
      scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scroll.heightAnchor.constraint(equalToConstant: 500),
      
      killButton.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      killButton.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      repoButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      repoButton.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    
    
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.dataSource = self
    tableView.delegate = self
    addColumn(title: "Name")
    addColumn(title: "Type")
    addColumn(title: "Until")
    
    search.delegate = self
    
    service.getAbsent(allowUIAuth: false) { [weak self] list in
      self?.absent = list
      self?.handleFiltering()
      self?.tableView.reloadData()
      
    }
  }
  
  
  
  override func viewWillAppear() {
    super.viewWillAppear()
    service.getAbsent(allowUIAuth: true) { [weak self] list in
      self?.absent = list
      self?.handleFiltering()
      self?.tableView.reloadData()
      
    }
  }
}

private extension SearchAbsentViewController {
  func addColumn(title: String) {
    let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(title))
    column.headerCell.stringValue = title
    tableView.addTableColumn(column)
  }
  
  func handleFiltering() {
    guard !search.stringValue.isEmpty else {
      filtered = absent
      tableView.reloadData()
      return
    }
    self.filtered = absent.filter({
      $0.name.lowercased().contains(search.stringValue.lowercased())
    })
    tableView.reloadData()
  }
  
  @objc func turnOff() {
    NSApp.terminate(self)
  }
  
  @objc func github() {
    NSWorkspace.shared.open(URL(string: "https://github.com/moscich/AbsenceTracker")!)
  }
}

extension SearchAbsentViewController: NSTableViewDataSource, NSTableViewDelegate {
  func numberOfRows(in tableView: NSTableView) -> Int {
    return filtered.count
  }
  
  func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
    return 40
  }
  
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("person"), owner: self) as? NSTextField ?? NSTextField()
    switch (tableColumn?.identifier) {
    case NSUserInterfaceItemIdentifier("Name"): cell.stringValue = filtered[row].name
    case NSUserInterfaceItemIdentifier("Type"): cell.stringValue = filtered[row].type.string
    case NSUserInterfaceItemIdentifier("Until"): cell.stringValue = RFC3339DateFormatter.string(from: filtered[row].until)
    default: break
    }
    if filtered[row].approved {
      cell.textColor = .white
    } else {
      cell.textColor = .gray
    }
    return cell
  }
}

extension SearchAbsentViewController: NSSearchFieldDelegate {
  func controlTextDidChange(_ obj: Notification) {
    if let textField = obj.object as? NSTextField, self.search.identifier == textField.identifier {
      handleFiltering()
    }
  }
  
  func controlTextDidEndEditing(_ obj: Notification) {
    print("Did end")
  }
  
  func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
    if (commandSelector == #selector(NSResponder.cancelOperation(_:)) && textView.string.isEmpty) {
      CCNStatusItem.sharedInstance()?.dismissWindow()
      return true
    }
    
    return false
  }
}
