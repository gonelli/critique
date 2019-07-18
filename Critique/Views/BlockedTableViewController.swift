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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        blockList = []
        
        db.collection("users").document(Auth.auth().currentUser!.uid).getDocument() { (document, error) in
            if error == nil {
                let blocked = document!.data()!["blocked"] as! [String]
                var criticsGotten = 0
                for blockedCritic in blocked {
                    self.db.collection("users").document(blockedCritic).getDocument() { (document, error) in
                        if error == nil {
                            self.blockList.append((document!.data()!["name"] as! String, blockedCritic))
                            criticsGotten += 1
                            if criticsGotten == blocked.count {
                                self.tableView.reloadData()
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "blockedCell", for: indexPath)
        
        cell.textLabel?.text = blockList[indexPath.row].0
        
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
