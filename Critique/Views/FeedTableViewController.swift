//
//  FeedTableViewController.swift
//  Critique
//
//  Created by James Jackson on 7/6/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import NightNight

class FeedTableViewController: UITableViewController {
    
    var db: Firestore!
    var reviews: [Review] = []
    let expandedReviewSegueID = "expandedReviewSegueID"
    let mixedNightBgColor = MixedColor(normal: 0xffffff, night: 0x222222)
    let mixedNightTextColor = MixedColor(normal: 0x000000, night: 0xdddddd)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addRefreshView()
        initializeFirestore()
        
        // NightNight
        self.navigationController!.navigationBar.mixedBarTintColor = MixedColor(normal: UIColor(red: 0.969, green: 0.969, blue: 0.969, alpha: 1.0), night: UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0))
        self.navigationController!.navigationBar.mixedBarStyle = MixedBarStyle(normal: .default, night: .black)
        self.tabBarController!.tabBar.mixedBarTintColor = mixedNightBgColor
//        self.tabBarController!.tabBar.mixedBarTintColor = MixedColor(normal: UIColor.white, night: UIColor.black) // Black tab bar
        if(NightNight.theme == .night) { // Idk but it works to fix statusbar color
            NightNight.theme = .night
        }
        else {
            NightNight.theme = .normal
        }
        
        view.mixedBackgroundColor = mixedNightBgColor
        tableView.mixedBackgroundColor = mixedNightBgColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if Auth.auth().currentUser != nil {
            getReviews()
        }
        
        // NightNight exception
        if (NightNight.theme == .night) {
            self.navigationController!.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(red:0.87, green:0.87, blue:0.87, alpha:1.0)] // 0xdddddd
        }
        else {
            self.navigationController!.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        }
    }
    
    // Either get reviews for valid user or direct them to create a new account
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (Auth.auth().currentUser == nil) {
            self.performSegue(withIdentifier: "toCreateAccount", sender: self)
        }
    }
    
    @objc func refresh() {
        getReviews()
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
    
    // Fetches reviews of critics user is following and populates the feed
    func getReviews() {
        var reviews: [Review] = []
        var usersGotten = 0
        db.collection("users").document("\(Auth.auth().currentUser!.uid)").getDocument { (document, error) in
            if var following = document?.data()?["following"] as? [String] {
                if following.count == 0 {
                    self.reviews = []
                    self.tableView.reloadData()
                    self.tableView.refreshControl?.endRefreshing()
                }
                following.append(Auth.auth().currentUser!.uid)
                for followed in following {
                    self.db.collection("reviews").whereField("criticID", isEqualTo: followed).getDocuments(completion: { (snapshot, _) in
                        for review in snapshot!.documents {
                            let body = review.data()["body"] as! String
                            let score = review.data()["score"] as! NSNumber
                            let criticID = review.data()["criticID"] as! String
                            let imdbID = review.data()["imdbID"] as! String
                            let likers = review.data()["liked"] as! [String]
                            let dislikers = review.data()["disliked"] as! [String]
                            let timestamp = review.data()["timestamp"] as! TimeInterval
                            reviews.append(Review(imdbID: imdbID, criticID: criticID, likers: likers, dislikers: dislikers, body: body, score: score, timestamp: timestamp))
                        }
                        usersGotten += 1
                        if usersGotten == following.count {
                            self.reviews = reviews.sorted()
                            self.tableView.reloadData()
                            self.tableView.refreshControl?.endRefreshing()
                        }
                    })
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reviews.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "feedCell", for: indexPath) as! FeedTableViewCell
        cell.review = reviews[indexPath.row]
        
        // NIGH NIGHT
        cell.criticLabel.mixedTextColor = mixedNightTextColor
        cell.likesLabel.mixedTextColor = mixedNightTextColor
        cell.reviewLabel.mixedTextColor = mixedNightTextColor
        cell.scoreLabel.mixedTextColor = mixedNightTextColor
        cell.movieLabel.mixedTextColor = mixedNightTextColor
        cell.mixedBackgroundColor = mixedNightBgColor
        cell.mixedTintColor = mixedNightTextColor
        
        cell.selectionStyle = .none
        
        return cell
    }
    
    // If body of a review is touched, open an expanded view of it
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == expandedReviewSegueID, let nextVC = segue.destination as? ExpandedReviewTableViewController , let reviewIndex = tableView.indexPathForSelectedRow?.row {
            nextVC.deligate = self
            nextVC.expanedReview = reviews[reviewIndex]
        }
    }
}
