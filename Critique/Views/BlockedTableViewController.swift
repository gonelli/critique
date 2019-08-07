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
import NightNight

class BlockedTableViewController: UITableViewController {
    
    var blockList : [(String, String)] = []
    var db: Firestore!
    let mixedNightBgColor = MixedColor(normal: 0xffffff, night: 0x222222)
    let mixedNightTextColor = MixedColor(normal: 0x000000, night: 0xdddddd)
    
    // Fetch and populate table with list of blocked users
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeFirestore()
        self.navigationItem.title = "Blocked"

        // NightNight
        tableView.mixedBackgroundColor = mixedNightBgColor
        view.mixedBackgroundColor = mixedNightBgColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        db.collection("users").document(Auth.auth().currentUser!.uid).getDocument() { (document, error) in
            if error == nil {
                var blockList: [(String, String)] = []
                let blocked = document!.data()!["blocked"] as! [String]
                if blocked.count == 0 {
                    self.blockList = []
                    self.tableView.reloadData()
                }
                var criticsGotten = 0
                for blockedCritic in blocked {
                    self.db.collection("users").document(blockedCritic).getDocument() { (document, error) in
                        if error == nil {
                            blockList.append((document!.data()!["name"] as! String, blockedCritic))
                            criticsGotten += 1
                            if criticsGotten == blocked.count {
                                self.blockList = blockList.sorted(by: <)
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
        
        // NightNight exception
        if (NightNight.theme == .night) {
            self.navigationController!.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(red:0.87, green:0.87, blue:0.87, alpha:1.0)]
        }
        else {
            self.navigationController!.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
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
        cell.setCell(name: blockList[indexPath.row].0, followers: 0, following: 0)
        cell.followLabel.text = ""

        // NightNight
        cell.selectionStyle = .none
        cell.mixedBackgroundColor = mixedNightBgColor
        cell.nameLabel?.mixedTextColor = mixedNightTextColor

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
