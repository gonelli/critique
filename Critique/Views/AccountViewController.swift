//
//  AccountViewController.swift
//  Critique
//
//  Created by Tony Gonelli on 7/2/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import UIKit
import Foundation

class AccountViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var accountTabLabel: UILabel!
    @IBOutlet weak var followersButtonOutlet: UIButton!
    @IBOutlet weak var followingButtonOutlet: UIButton!
    
    var db: Firestore!
    var accountName = ""
    var accountID = ""
    var num_following = 0
    var num_followers = 0
    var reviews: [Review] = [] {
        didSet {
            self.tableView.reloadData() // Reload table after reviews are fetched
        }
    }
    let followersSegue = "followersSegue"
    let followingSegue = "followingSegue"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("--viewDidLoad--")
        
        tableView.delegate = self
        tableView.dataSource = self
        addRefreshView()
        initializeFirestore()
        
        // Brings up table behind overlapping tab bar
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 77, right: 0)
    }
    
    // Fill in details of page based on whose Profile it is
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("--viewDidAppear--")
        
        // Looking at own profile
        if accountName == "" || accountID == "" || accountID == Auth.auth().currentUser!.uid {
            accountID = Auth.auth().currentUser!.uid
            db.collection("users").document(accountID).getDocument() { (document, error) in
                if error == nil {
                    self.accountName = document!.data()!["name"] as! String
                    self.navigationController?.navigationBar.topItem?.title = self.accountName
                    self.getReviews()
                    self.getFollowNumbers()
                }
                else {
                    fatalError(error!.localizedDescription)
                }
            }
        }
        // Looking at another critic's profile
        else {
            getReviews()
            getFollowNumbers()
            self.navigationController?.navigationBar.topItem?.title = self.accountName
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "•••", style: .done, target: self, action: #selector(self.accountAction))
        }
    }
    
    @objc func refresh() {
        print("--refesh--")
        getReviews()
        getFollowNumbers()
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
    
    // Fetches reviews of critics user is following and populates the account page
    func getReviews() {
        var reviews: [Review] = []
        db.collection("reviews").document("\(Auth.auth().currentUser!.uid)").getDocument { (document, error) in
            self.db.collection("reviews").whereField("criticID", isEqualTo: self.accountID).getDocuments(completion: { (snapshot, _) in
                //TODO: custom MovieInfoCell, not FeedTableViewCell
                for review in snapshot!.documents {
                    let body = review.data()["body"] as! String
                    let score = review.data()["score"] as! NSNumber
                    let criticID = review.data()["criticID"] as! String
                    let imdbID = review.data()["imdbID"] as! String
                    let timestamp = review.data()["timestamp"] as! TimeInterval
                    reviews.append(Review(imdbID: imdbID, criticID: criticID, body: body, score: score, timestamp: timestamp))
                }
                self.reviews = reviews
                self.tableView.refreshControl?.endRefreshing()
            })
        }
    }
    
    func getFollowNumbers() {
        print("\nCrash0--\(accountID)\n")
        // Number of Following
        db.collection("users").document(accountID).getDocument { (document, error) in
            if error == nil {
                let followingList = document!.data()!["following"] as! [String]
                self.num_following = followingList.count
            }
            self.followingButtonOutlet.setTitle("\(self.num_following) Following",for: .normal)
        }
        
        // Number of Followers
        self.num_followers = 0
        db.collection("users").getDocuments{ (snapshot, _) in
            for critic in snapshot!.documents {
                for following in critic.data()["following"] as! [String] {
                    if following == self.accountID {
                        self.num_followers += 1
                    }
                }
            }
            self.followersButtonOutlet.setTitle("\(self.num_followers) Followers",for: .normal)
        }
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.reviews.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "accountReviewCell", for: indexPath) as! FeedTableViewCell
        cell.review = self.reviews[indexPath.row]
        return cell
    }

    // Segue to Following/Followers/Expanded screens
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == followersSegue {
            let nextVC = segue.destination as! FollowsTableViewController
            nextVC.lookupType = "Followers"
            nextVC.user = accountID
        }
        else if segue.identifier == followingSegue {
            let nextVC = segue.destination as! FollowsTableViewController
            nextVC.lookupType = "Following"
            nextVC.user = accountID
        }
        else if segue.identifier == "accountMovieExpandSegue", let nextVC = segue.destination as? ExpandedReviewTableViewController , let reviewIndex = tableView.indexPathForSelectedRow?.row {
            nextVC.deligate = self
            nextVC.expanedReview = reviews[reviewIndex]
        }
    }

    // Generate action screen for when user clicks on options button
    @objc func accountAction() {
        let controller = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet)
        
        let blockAction = UIAlertAction(
            title: "Block",
            style: .destructive,
            handler:  {(alert) in
                let ref = self.db.collection("users").document(Auth.auth().currentUser!.uid)
                ref.getDocument { (document, error) in
                    if error == nil {
                        // When blocked button pressed
                        var blocked = document!.data()!["blocked"] as! [String]
                        blocked.append(self.accountID)
                        var following = document!.data()!["following"] as! [String]
                        following.removeAll { $0 == self.accountID }
                        ref.setData(["blocked": blocked], merge: true)
                        ref.setData(["following": following], merge: true)
                        let refBlocked = self.db.collection("users").document(self.accountID)
                        refBlocked.getDocument() { (document, error) in
                            following = document!.data()!["following"] as! [String]
                            following.removeAll { $0 == Auth.auth().currentUser!.uid }
                            refBlocked.setData(["following": following], merge: true)
                        }
                    }
                    else {
                        fatalError(error!.localizedDescription)
                    }
                }
            }
        )
        
        let unblockAction = UIAlertAction(
            title: "Unblock",
            style: .destructive,
            handler:  {(alert) in
                let ref = self.db.collection("users").document("\(Auth.auth().currentUser!.uid)")
                ref.getDocument { (document, error) in
                    if error == nil {
                        // When unblock pressed
                        var blocked = document!.data()!["blocked"] as! [String]
                        blocked.removeAll { $0 == self.accountID }
                        ref.setData(["blocked": blocked], merge: true)
                    }
                    else {
                        fatalError(error!.localizedDescription)
                    }
                }
            }
        )
        
        let messageAction = UIAlertAction(
            title: "Message",
            style: .default
        )
        
        let ref = self.db.collection("users").document("\(Auth.auth().currentUser!.uid)")
        
        let followAction = UIAlertAction(
            title: "Follow",
            style: .default,
            handler: {(alert) in
                ref.getDocument { (document, error) in
                    if error == nil {
                        // When follow pressed
                        var following = document!.data()!["following"] as! [String]
                        following.append(self.accountID)
                        ref.setData(["following": following], merge: true)
                    }
                    else {
                        fatalError(error!.localizedDescription)
                    }
                }
            }
        )
        
        let unfollowAction = UIAlertAction(
            title: "Unfollow",
            style: .default,
            handler: {(alert) in
                ref.getDocument { (document, error) in
                    if error == nil {
                        // When unfollow pressed
                        var following = document!.data()!["following"] as! [String]
                        following.removeAll { $0 == self.accountID }
                        ref.setData(["following": following], merge: true)
                    }
                    else {
                        fatalError(error!.localizedDescription)
                    }
                }
            }
        )
        
        let cancelAction = UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: { (action) in print("Cancel Action")}
        )
        
        messageAction.setValue(UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0), forKey: "titleTextColor")
        unfollowAction.setValue(UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0), forKey: "titleTextColor")
        followAction.setValue(UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0), forKey: "titleTextColor")
        cancelAction.setValue(UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0), forKey: "titleTextColor")
        
        // Selectively include options based on if they are blocked or followed
        ref.getDocument { (document, error) in
            if error == nil {
                let following = document!.data()!["following"] as! [String]
                let blocked = document!.data()!["blocked"] as! [String]
                if following.contains(self.accountID) {
                    controller.addAction(unfollowAction)
                    controller.addAction(messageAction)
                }
                else if !blocked.contains(self.accountID) {
                    controller.addAction(followAction)
                    controller.addAction(messageAction)
                }
                if blocked.contains(self.accountID) {
                    controller.addAction(unblockAction)
                }
                else {
                    controller.addAction(blockAction)
                }
                controller.addAction(cancelAction)
                self.present(controller, animated: true, completion: nil)
            }
            else {
                fatalError(error!.localizedDescription)
            }
        }
    }

}
