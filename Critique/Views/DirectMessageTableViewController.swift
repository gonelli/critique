//
//  DirectMessageTableViewController.swift
//  Critique
//
//  Created by Andrew Cramer on 7/18/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit
import Firebase

class DirectMessageTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate{

    var db: Firestore!
    var chat:Chat? = nil
    var messageCount:Int = 0
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTF: UITextField!
    
    @IBAction func sendButton(_ sender: Any) {
        if messageTF.text != nil, let tf = messageTF.text {
            chat!.messages.append(contentsOf: [["body": tf, "from": chat!.criticIDs.firstIndex(of: Auth.auth().currentUser!.uid)!, "time": Date()]])
            db.collection("chats").document(chat!.chatID).setData(["messages": chat!.messages], merge: true)
            messageTF.text = ""
            tableView.reloadData()
            //tableView.scrollToRow(at: IndexPath(row: tableView.numberOfRows(inSection: 0) - 1, section: 0), at: .bottom, animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        db = Firestore.firestore()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        chat?.getMessages() { (messages) in
            self.messageCount = messages.count
            self.tableView.reloadData()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chat?.messages.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        print("\nGot here\n")
        let cell = UITableViewCell()
        if chat!.isCurrentUser(indexPath.row) {
            cell.textLabel?.textAlignment = .right
            cell.textLabel?.backgroundColor = UIColor.blue
        }
        chat?.getMessages(){ (messages) in
            print("\nMessages:\(messages)\n")
            cell.textLabel?.text = messages[indexPath.row]["body"] as! String?
        }

        return cell
    }
    
}
