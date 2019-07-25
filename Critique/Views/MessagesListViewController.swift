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

class MessagesListViewController: UITableViewController {
  
  var db: Firestore!
  var directMessages: [Chat] = [] {
    didSet {
      self.tableView.reloadData() // Reload table after reviews are fetched
    }
  }
  var snapshotListener:ListenerRegistration! = nil
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.title = "Messages"
    addRefreshView()
    initializeFirestore()
    //getDirectMessages()
  }
    
    override func viewDidAppear(_ animated: Bool) {
        snapshotListener = db.collection("users").document(Auth.auth().currentUser!.uid).addSnapshotListener() { document, error in
            self.refresh()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        snapshotListener.remove()
        for cellIndex in 0...(tableView.numberOfRows(inSection: 0)-1){
            let cell = tableView.cellForRow(at: IndexPath(row: cellIndex, section: 0)) as! ChatTableViewCell
            cell.removeListener()
        }
    }
  
  @objc func refresh() {
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
    var directMessages: [Chat] = []
    db.collection("users").document("\(Auth.auth().currentUser!.uid)").getDocument { (document, error) in
      if let myChats = document?.data()?["myChats"] as? [String] {
        var syncCount = myChats.count
        for chat in myChats {
          directMessages.append(Chat(chat) { () in
            syncCount -= 1
            if syncCount <= 0 {
              directMessages.sort() { (chat1, chat2) in
                if let time1 = chat1.getTimestamp(), let time2 = chat2.getTimestamp() {
                    if time1.timeIntervalSince1970 > time2.timeIntervalSince1970 {
                        print("again")
                        return true
                    }
                }
                return false
              }
              self.directMessages = directMessages
            }
          })
        }
        self.tableView.refreshControl?.endRefreshing()
      }
    }
  }
    
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return directMessages.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "chatCell", for: indexPath) as! ChatTableViewCell
    cell.chat = directMessages[indexPath.row]
    cell.setListener()
    return cell
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    let nextVC = segue.destination as! ChatViewController
    if segue.identifier == "toChat", let selectedRow = tableView.indexPathForSelectedRow {
      nextVC.chat = directMessages[selectedRow.row]
    }
  }
    
    
  
}
