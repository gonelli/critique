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
    
    @IBOutlet weak var titleLabel: UINavigationItem!
    
    var db: Firestore!
    var lookupType: String = "Following"
    var user: String!
    var critics: [(String, String)] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addRefreshView()
        initializeFirestore()
        if (Auth.auth().currentUser != nil) {
            getCritics()
        }
        titleLabel.title = lookupType
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return critics.count
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (Auth.auth().currentUser == nil) {
            self.performSegue(withIdentifier: "toCreateAccount", sender: self)
        }
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
    
    func getCritics() {
        var critics: [(String, String)] = []
        if lookupType == "Following" {
            db.collection("users").document(self.user).getDocument { (document, _) in
                if let following = document?.data()?["following"] as? [String] {
                    for followed in following {
                        self.db.collection("users").document(followed).getDocument{ (snapshot, _) in
                            critics.append((snapshot?.data()?["name"] as! String, followed))
                            self.critics = critics
                        }
                    }
                    self.tableView.refreshControl?.endRefreshing()
                }
            }
        }
        else {
            db.collection("users").getDocuments{ (snapshot, _) in
                for critic in snapshot!.documents {
                    for following in critic.data()["following"] as! [String] {
                        if following == self.user {
                            // TODO: 'following' is not the right id. Must get id from follower
                            critics.append((critic.data()["name"] as! String, following))
                        }
                    }
                }
                self.critics = critics
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
