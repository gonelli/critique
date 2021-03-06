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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.isUserInteractionEnabled = false
        directMessages = []
        tableView.reloadData()
        self.tableView.isUserInteractionEnabled = true
        getDirectMessages()
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
        var directMessages: [Chat] = []
        db.collection("users").document("\(Auth.auth().currentUser!.uid)").getDocument { (document, error) in
            if let myChats = document?.data()?["myChats"] as? [String] {
                var syncCount = myChats.count
                if syncCount == 0 {
                    self.directMessages = []
                }
                for chat in myChats {
                    directMessages.append(Chat(chat) { () in
                        syncCount -= 1
                        if syncCount <= 0 {
                            directMessages.sort() { (chat1, chat2) in
                                if let time1 = chat1.getTimestamp(), let time2 = chat2.getTimestamp() {
                                    if time1.timeIntervalSince1970 > time2.timeIntervalSince1970 {
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
    
    func sortDMs() {
        directMessages.sort() { (chat1, chat2) in
            if let time1 = chat1.getTimestamp(), let time2 = chat2.getTimestamp() {
                if time1.timeIntervalSince1970 > time2.timeIntervalSince1970 {
                    return true
                }
            }
            return false
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return directMessages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatCell", for: indexPath) as! ChatTableViewCell
        cell.chat = directMessages[indexPath.row]
        cell.delegate = self
        cell.setListener()
        
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
                    self.tableView.isUserInteractionEnabled = false
                    var chats = document!.data()!["myChats"] as! [String]
                    chats.remove(at: chats.firstIndex(of: self.directMessages[editActionsForRowAt.row].chatID)!)
                    docRef.setData(["myChats": chats], merge: true)
                    (tableView.cellForRow(at: editActionsForRowAt) as! ChatTableViewCell).removeListener()
                    self.directMessages.remove(at: editActionsForRowAt.row)
                    tableView.reloadData()
                    self.tableView.isUserInteractionEnabled = true
                }
                else {
                    fatalError(error!.localizedDescription)
                }
            }
        }
        return [hide]
    }
    
    
}
