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
    
    // Fetch and populate table with list of blocked users
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeFirestore()
        self.navigationItem.title = "Blocked"
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        db.collection("users").document(Auth.auth().currentUser!.uid).getDocument() { (document, error) in
            if error == nil {
                var blockList: [(String, String)] = []
                let blocked = document!.data()!["blocked"] as! [String]
                if blocked.count == 0 {
                    self.tableView.isUserInteractionEnabled = false
                    self.blockList = []
                    self.tableView.reloadData()
                    self.tableView.isUserInteractionEnabled = true
                }
                var criticsGotten = 0
                for blockedCritic in blocked {
                    self.db.collection("users").document(blockedCritic).getDocument() { (document, error) in
                        if error == nil {
                            blockList.append((document!.data()!["name"] as! String, blockedCritic))
                            criticsGotten += 1
                            if criticsGotten == blocked.count {
                                self.tableView.isUserInteractionEnabled = false
                                self.blockList = blockList.sorted(by: <)
                                self.tableView.reloadData()
                                self.tableView.isUserInteractionEnabled = true
                            }
                        }
                        else {
                            fatalError(error!.localizedDescription)
                        }
                    }
                }
            }
            else {
                fatalError(error!.localizedDescription)
            }
        }
        
    }
    
    func initializeFirestore() {
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        self.db = Firestore.firestore()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showBlockedCritic", sender: self)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blockList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> DiscoveryTableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "blockedCell", for: indexPath) as! DiscoveryTableViewCell
        cell.setCell(name: blockList[indexPath.row].0, followers: 0, following: 0, uid: blockList[indexPath.row].1)
        cell.followLabel.text = ""
        
        cell.selectionStyle = .none        
        return cell
    }
    
    // Segue to selected blocked critic's Profile page
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showBlockedCritic" {
            let profileVC = segue.destination as! AccountViewController
            let selectedRow = tableView.indexPathForSelectedRow!
            profileVC.accountName = self.blockList[selectedRow.row].0
            profileVC.accountID = self.blockList[selectedRow.row].1
            
            tableView.deselectRow(at: selectedRow, animated: true)
        }
        else {
            fatalError("Unknown segue identifier")
        }
    }
    
    
}
