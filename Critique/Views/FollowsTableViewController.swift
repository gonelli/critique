//
//  FollowsTableViewController.swift
//  Critique
//
//  Created by Andrew Cramer on 7/11/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import NightNight

class FollowsTableViewController: UITableViewController {
  
    var db: Firestore!
    var lookupType: String = "Following"
    var user: String!
    var critics: [(String, String)] = []
    let mixedNightBgColor = MixedColor(normal: 0xffffff, night: 0x222222)
    let mixedNightTextColor = MixedColor(normal: 0x000000, night: 0xdddddd)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = lookupType
        addRefreshView()
        initializeFirestore()
        
        // NightNight
        tableView.mixedBackgroundColor = mixedNightBgColor
        view.mixedBackgroundColor = mixedNightBgColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getCritics()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return critics.count
    }
    
    @objc func refresh() {
        getCritics()
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
    
    // Get all the critics to populate the table
    func getCritics() {
        var critics: [(String, String)] = []
        // Get all critics the user is following
        if lookupType == "Following" {
            db.collection("users").document(self.user).getDocument { (document, _) in
                if let following = document?.data()?["following"] as? [String] {
                    if following.count == 0 {
                        self.critics = []
                        self.tableView.reloadData()
                        self.tableView.refreshControl?.endRefreshing()
                    }
                    var criticsGotten = 0
                    for followed in following {
                        self.db.collection("users").document(followed).getDocument{ (snapshot, _) in
                            critics.append((snapshot?.data()?["name"] as! String, followed))
                            criticsGotten += 1
                            if criticsGotten == following.count {
                                self.critics = critics
                                self.tableView.reloadData()
                                self.tableView.refreshControl?.endRefreshing()
                            }
                        }
                    }
                }
            }
        }
        // Get all critics the user is followed by
        else {
            db.collection("users").getDocuments{ (snapshot, _) in
                for critic in snapshot!.documents {
                    if (critic.data()["isPublic"] as! Bool) {
                        for following in critic.data()["following"] as! [String] {
                            if following == self.user {
                                critics.append((critic.data()["name"] as! String, critic.documentID))
                            }
                        }
                    }
                }
                self.critics = critics
                self.tableView.reloadData()
                self.tableView.refreshControl?.endRefreshing()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "criticCell", for: indexPath)
        cell.textLabel?.text = critics[indexPath.row].0
        
        // NightNight
        cell.mixedBackgroundColor = mixedNightBgColor
        cell.textLabel?.mixedTextColor = mixedNightTextColor
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showFollowCritic", sender: self)
    }
    
    // Segue to selected critic's Profile
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showFollowCritic" {
            let profileVC = segue.destination as! AccountViewController
            let selectedRow = tableView.indexPathForSelectedRow!
            profileVC.accountName = self.critics[selectedRow.row].0
            profileVC.accountID = self.critics[selectedRow.row].1
            
            tableView.deselectRow(at: selectedRow, animated: true)
        }
        else {
            fatalError("Unknown segue identifier")
        }
    }
}
