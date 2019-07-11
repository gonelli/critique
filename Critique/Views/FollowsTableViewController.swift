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
    var critics: [String] = [] {
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
        var critics: [String] = []
        if lookupType == "Following" {
            db.collection("users").document("\(Auth.auth().currentUser!.uid)").getDocument { (document, error) in
                if let following = document?.data()?["following"] as? [String] {
                    for followed in following {
                        self.db.collection("users").document(followed).getDocument(){ (snapshot, _) in
                            critics.append(snapshot?.data()?["name"] as! String)
                        }
                    }
                    self.critics = critics
                    self.tableView.refreshControl?.endRefreshing()
                }
            }
        } else {
            
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "criticCell", for: indexPath)
        cell.textLabel?.text = critics[indexPath.row]
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == expandedReviewSegueID, let nextVC = segue.destination as? ExpandedReviewTableViewController , let reviewIndex = tableView.indexPathForSelectedRow?.row {
//            nextVC.deligate = self
//            nextVC.expanedReview = reviews[reviewIndex]
//        }
    }

}
