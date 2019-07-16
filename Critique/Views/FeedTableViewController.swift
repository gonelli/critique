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

class FeedTableViewController: UITableViewController {
    
    var db: Firestore!
    var reviews: [Review] = [] {
        didSet {
            self.tableView.reloadData() // Reload table after reviews are fetched
        }
    }
    let expandedReviewSegueID = "expandedReviewSegueID"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addRefreshView()
        initializeFirestore()
        if (Auth.auth().currentUser != nil) {
            getReviews()
        }
    }
    
    // Either get reviews for valid user or direct them to create a new account
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (Auth.auth().currentUser == nil) {
            self.performSegue(withIdentifier: "toCreateAccount", sender: self)
        }
        else {
            getReviews()
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
        db.collection("users").document("\(Auth.auth().currentUser!.uid)").getDocument { (document, error) in
            if let following = document?.data()?["following"] as? [String] {
                for followed in following {
                    self.db.collection("reviews").whereField("criticID", isEqualTo: followed).getDocuments(completion: { (snapshot, _) in
                        for review in snapshot!.documents {
                            let body = review.data()["body"] as! String
                            let score = review.data()["score"] as! NSNumber
                            let criticID = review.data()["criticID"] as! String
                            let imdbID = review.data()["imdbID"] as! String
                            reviews.append(Review(imdbID: imdbID, criticID: criticID, body: body, score: score))
                        }
                        self.reviews = reviews
                        self.tableView.refreshControl?.endRefreshing()
                    })
                }
                self.tableView.refreshControl?.endRefreshing()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reviews.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "feedCell", for: indexPath) as! FeedTableViewCell
        cell.review = reviews[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt: IndexPath) -> [UITableViewRowAction]? {
        let swipedCriticID = self.reviews[editActionsForRowAt[1]].criticID!
        let swipedMovieID = self.reviews[editActionsForRowAt[1]].imdbID!
        let ref = self.db.collection("reviews").document(swipedCriticID + "_" + swipedMovieID)

        let like = UITableViewRowAction(style: .normal, title: "Like") { action, index in
            ref.getDocument { (document, error) in
                if error == nil {
                    // When follow pressed
                    var liked = document!.data()!["liked"] as! [String]
                    var disliked = document!.data()!["disliked"] as! [String]
                    let userID = Auth.auth().currentUser!.uid
                    if liked.contains(userID) {
                        if let index = liked.firstIndex(of: userID) {
                            liked.remove(at: index)
                        }
                    }
                    else {
                        if disliked.contains(userID) {
                            if let index = disliked.firstIndex(of: userID) {
                                disliked.remove(at: index)
                            }
                        }
                        liked.append(Auth.auth().currentUser!.uid)
                    }
                    ref.setData(["liked": liked], merge: true)
                    ref.setData(["disliked": disliked], merge: true)
                }
                else {
                    fatalError(error!.localizedDescription)
                }
            }
        }
        like.backgroundColor = .red
        
        let dislike = UITableViewRowAction(style: .normal, title: "Dislike") { action, index in
            ref.getDocument { (document, error) in
                if error == nil {
                    // When follow pressed
                    var liked = document!.data()!["liked"] as! [String]
                    var disliked = document!.data()!["disliked"] as! [String]
                    let userID = Auth.auth().currentUser!.uid
                    
                    if disliked.contains(userID) {
                        if let index = disliked.firstIndex(of: userID) {
                            disliked.remove(at: index)
                        }
                    }
                    else {
                        if liked.contains(userID) {
                            if let index = liked.firstIndex(of: userID) {
                                liked.remove(at: index)
                            }
                        }
                        disliked.append(Auth.auth().currentUser!.uid)
                    }
                    ref.setData(["liked": liked], merge: true)
                    ref.setData(["disliked": disliked], merge: true)
                }
                else {
                    fatalError(error!.localizedDescription)
                }
            }
        }
        dislike.backgroundColor = .blue
        
        return [dislike, like]
    }

    // If body of a review is touched, open an expanded view of it
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == expandedReviewSegueID, let nextVC = segue.destination as? ExpandedReviewTableViewController , let reviewIndex = tableView.indexPathForSelectedRow?.row {
            nextVC.deligate = self
            nextVC.expanedReview = reviews[reviewIndex]
        }
    }
}
