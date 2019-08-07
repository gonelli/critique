//
//  MessagesViewController.swift
//  Critique
//
//  Created by Tony Gonelli on 7/2/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import NightNight

class MessagesListViewController: UITableViewController {
  
  var db: Firestore!
  var directMessages: [Chat] = [] {
    didSet {
      self.tableView.reloadData() // Reload table after reviews are fetched
    }
  }
  var snapshotListener:ListenerRegistration! = nil
  let mixedNightBgColor = MixedColor(normal: 0xffffff, night: 0x222222)
  let mixedNightTextColor = MixedColor(normal: 0x000000, night: 0xdddddd)
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.title = "Messages"
    addRefreshView()
    initializeFirestore()
    
    // NightNight
    self.navigationController!.navigationBar.mixedBarTintColor = MixedColor(normal: UIColor(red: 0.969, green: 0.969, blue: 0.969, alpha: 1.0), night: UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0))
    self.navigationController!.navigationBar.mixedBarStyle = MixedBarStyle(normal: .default, night: .black)
    tableView.mixedBackgroundColor = mixedNightBgColor
    if(NightNight.theme == .night) { // Idk but it works to fix statusbar color
        NightNight.theme = .night
    }
    else {
        NightNight.theme = .normal
    }
  }
    
    override func viewWillAppear(_ animated: Bool) {
        directMessages = []
        tableView.reloadData()
        getDirectMessages()
        // NightNight exception
        if (NightNight.theme == .night) {
            self.navigationController!.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(red:0.87, green:0.87, blue:0.87, alpha:1.0)]
        }
        else {
            self.navigationController!.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        snapshotListener = db.collection("users").document(Auth.auth().currentUser!.uid).addSnapshotListener() { document, error in
            self.refresh()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        snapshotListener.remove()
        if (tableView.numberOfRows(inSection: 0) == 0) {
            return
        }
        for cellIndex in 0...(tableView.numberOfRows(inSection: 0)-1){
            let cell = tableView.cellForRow(at: IndexPath(row: cellIndex, section: 0)) as! ChatTableViewCell
            cell.removeListener()
        }
    }
  
  @objc func refresh() {
    if tableView.numberOfRows(inSection: 0) != 0 {
        for cellIndex in 0...(tableView.numberOfRows(inSection: 0)-1){
            let cell = tableView.cellForRow(at: IndexPath(row: cellIndex, section: 0)) as! ChatTableViewCell
            cell.removeListener()
        }
    }
    getDirectMessages()
  }
  
  func addRefreshView() {
    let refresh = UIRefreshControl()
    tableView.refreshControl = refresh
    refresh.addTarget(self, action: #selector(self.refresh), for: .valueChanged)
  }
  
  func initializeFirestore() {
    let settings = FirestoreSettings()
    Firestore.firestore().settings = settings
    db = Firestore.firestore()
  }
  
  // Fetches messages
  func getDirectMessages() {
    print("getDMs")
    var directMessages: [Chat] = []
    db.collection("users").document("\(Auth.auth().currentUser!.uid)").getDocument { (document, error) in
      if let myChats = document?.data()?["myChats"] as? [String] {
        var syncCount = myChats.count
        for chat in myChats {
          directMessages.append(Chat(chat) { () in
            syncCount -= 1
            if syncCount <= 0 {
                self.directMessages = directMessages
                self.sortDMs()
            }
          })
        }
//        self.tableView.reloadData()
        self.tableView.refreshControl?.endRefreshing()
      }
    }
  }
    
  func sortDMs() {
//    print("0: \(directMessages[0].chatID), \(directMessages[1].chatID)")
    directMessages.sort() { (chat1, chat2) in
      if let time1 = chat1.getTimestamp(), let time2 = chat2.getTimestamp() {
        if time1.timeIntervalSince1970 > time2.timeIntervalSince1970 {
          return true
        }
      }
      return false
    }
//    tableView.reloadData()
//    print("1: \(directMessages[0].chatID), \(directMessages[1].chatID)")
//    print("2: \((tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! ChatTableViewCell).chat!.chatID), \((tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as! ChatTableViewCell).chat!.chatID)")
  }
    
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return directMessages.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "chatCell", for: indexPath) as! ChatTableViewCell
    cell.chat = directMessages[indexPath.row]
    cell.delegate = self
    cell.setListener()
    
    // Avatars
    
    
    // NightNight
    cell.mixedBackgroundColor = mixedNightBgColor
    cell.titleLabel.mixedTextColor = mixedNightTextColor
    cell.selectionStyle = .none
    
    return cell
  }
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        (cell as! ChatTableViewCell).removeListener()
    }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    let nextVC = segue.destination as! ChatViewController
    if segue.identifier == "toChat", let selectedRow = tableView.indexPathForSelectedRow {
      nextVC.chat = directMessages[selectedRow.row]
        nextVC.incomingName = (tableView.cellForRow(at: IndexPath(row: selectedRow.row, section: 0)) as! ChatTableViewCell).titleLabel.text!
    }
  }
  
  
  override func tableView(_ tableView: UITableView, editActionsForRowAt: IndexPath) -> [UITableViewRowAction]? {
    let hide = UITableViewRowAction(style: .destructive, title: "Hide") { (action, editActionsForRowAt) in
      let docRef = self.db.collection("users").document(Auth.auth().currentUser!.uid)
      docRef.getDocument { (document, error) in
        if error == nil {
          var chats = document!.data()!["myChats"] as! [String]
          chats.remove(at: chats.firstIndex(of: self.directMessages[editActionsForRowAt.row].chatID)!)
          docRef.setData(["myChats": chats], merge: true)
            (tableView.cellForRow(at: editActionsForRowAt) as! ChatTableViewCell).removeListener()
            self.directMessages.remove(at: editActionsForRowAt.row)
            tableView.reloadData()
        }
        else {
          fatalError(error!.localizedDescription)
        }
      }
    }
    return [hide]
  }
  
  
}
