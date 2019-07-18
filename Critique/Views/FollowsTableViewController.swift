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

class FollowsTableViewController: UITableViewController {
  
    var db: Firestore!
    var lookupType: String = "Following"
    var user: String!
    var critics: [(String, String)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = lookupType
        addRefreshView()
        initializeFirestore()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.critics = []
        tableView.reloadData()
        getCritics()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return critics.count
    }
    
    @objc func refresh() {
        self.critics = []
        tableView.reloadData()
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
            print(self.critics[selectedRow.row].0)
            print(self.critics[selectedRow.row].1)
            
            tableView.deselectRow(at: selectedRow, animated: true)
        }
        else {
            fatalError("Unknown segue identifier")
        }
    }
}
