//
//  BlockedTableViewController.swift
//  Critique
//
//  Created by Tony Gonelli on 7/11/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//
import UIKit
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore


class BlockedTableViewController: UITableViewController {
    
    var blockList : [(String, String)] = []
    
    var db: Firestore!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeFirestore()
        db.collection("users").document(Auth.auth().currentUser!.uid).getDocument() { (document, error) in
            if error == nil {
                let blocked = document!.data()!["blocked"] as! [String]
                for blockedCritic in blocked {
                    self.db.collection("users").document(blockedCritic).getDocument() { (document, error) in
                        if error == nil {
                            self.blockList.append((document!.data()!["name"] as! String, blockedCritic))
                            self.tableView.reloadData()
                        } else {
                            fatalError(error!.localizedDescription)
                        }
                    }
                }
            } else {
                fatalError(error!.localizedDescription)
            }
        }
    }
    
    func initializeFirestore() {
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        self.db = Firestore.firestore()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blockList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "blockedCell", for: indexPath)
        
        cell.textLabel?.text = blockList[indexPath.row].0
        
        return cell
    }
    
}
