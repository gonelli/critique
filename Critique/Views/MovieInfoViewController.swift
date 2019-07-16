//
//  MovieInfoViewController.swift
//  Critique
//
//  Created by Ameya Joshi on 7/4/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

class MovieInfoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var segmentChanged: UISegmentedControl!
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet var scoreLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var yearLabel: UILabel!
    @IBOutlet var synopsisTextView: UITextView!
    @IBOutlet var updateButton: UIButton!
    @IBOutlet var posterImage: UIImageView!
    
    var movieTitle: String!
    var movieObject: Movie!
    var db: Firestore!
    var reviews: [Review] = [] {
        didSet {
            self.tableView.reloadData() // Reload table after reviews are fetched
        }
    }
    var followingReviews: [Review] = [] {
        didSet {
            self.tableView.reloadData() // Reload table after reviews are fetched
        }
    }
    var scores: [Double] = [] {
        didSet {
            self.tableView.reloadData() // Reload table after reviews are fetched
        }
    }
    let composeSegue = "composeSegue"

    // Load header - movie details, synopsis, average score, etc.
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = movieTitle
        posterImage.image = movieObject.poster
        synopsisTextView.text = movieObject.movieData["Plot"]! as? String
        synopsisTextView.isEditable = false
        posterImage.layer.masksToBounds = true
        posterImage.layer.borderWidth = 0
        posterImage.layer.borderColor = UIColor.lightGray.cgColor
        yearLabel.text = " \( movieObject.movieData["Year"]!)"
        yearLabel.textColor = UIColor.gray
        
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 77, right: 0)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Post", style: .done, target: self, action: #selector(self.post))
        
        tableView.delegate = self
        tableView.dataSource = self
        addRefreshView()
        initializeFirestore()
        getReviews()
    }
    
    func initializeFirestore() {
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        db = Firestore.firestore()
    }
    
    @objc func refresh() {
        if segmentedControl.selectedSegmentIndex == 0 {
            getReviews()
        }
        else {
            getFollowingReviews()
        }
    }
    
    func addRefreshView() {
        let refresh = UIRefreshControl()
        tableView.refreshControl = refresh
        refresh.addTarget(self, action: #selector(self.refresh), for: .valueChanged)
    }
  
    @objc func post() {
        performSegue(withIdentifier: "toCompose", sender: self)
    }
    
    @IBAction func updateButtonPressed(_ sender: Any) {
        posterImage.image = movieObject.poster
    }
    
    // Fetches reviews of critics user is following and populates the movie review page
    func getReviews() {
        var reviews: [Review] = []
        let currentMovieID = movieObject.movieData["imdbID"]!
        db.collection("reviews").document("\(Auth.auth().currentUser!.uid)").getDocument { (document, error) in
            self.db.collection("reviews").whereField("imdbID", isEqualTo: currentMovieID).getDocuments(completion: { (snapshot, _) in
                //TODO: custom MovieInfoCell, not FeedTableViewCell
                for review in snapshot!.documents {
                    let body = review.data()["body"] as! String
                    let score = review.data()["score"] as! NSNumber
                    self.scores.append(Double(truncating: score))
                    let avgScore = ((self.scores.reduce(0, +) / Double(self.scores.count)) * pow(10.0, Double(2))
                        ).rounded() / pow(10.0, Double(2))
                    self.scoreLabel.text = String(avgScore) + " / 10"
                    
                    let imdbID = review.data()["imdbID"] as! String
                    let criticID = review.data()["criticID"] as! String
                    self.db.collection("users").document(criticID).getDocument() { (document, error) in
                        if error == nil {
                            if (document!.data()!["isPublic"] as! Bool) {
                                // TO-DO: Block around reviews
                                reviews.append(Review(imdbID: imdbID, criticID: criticID, body: body, score: score))
                                self.reviews = reviews
                            }
                        }
                        else {
                            fatalError("Unknown user")
                        }
                    }
                    
                }
                self.reviews = reviews
                self.tableView.refreshControl?.endRefreshing()
            })
        }
        if (scores.count == 0) {
            self.scoreLabel.text = "No scores"
        }
    }
    
    func getFollowingReviews() {
        var followingReviews: [Review] = []
        let currentMovieID = movieObject.movieData["imdbID"] as! String
        
        db.collection("users").document("\(Auth.auth().currentUser!.uid)").getDocument { (document, error) in
            if let following = document?.data()?["following"] as? [String] {
                for followed in following {
                    self.db.collection("reviews").whereField("criticID", isEqualTo: followed).getDocuments(completion: { (snapshot, _) in
                        for review in snapshot!.documents {
                            let body = review.data()["body"] as! String
                            let score = review.data()["score"] as! NSNumber
                            let criticID = review.data()["criticID"] as! String
                            let imdbID = review.data()["imdbID"] as! String
                            
                            if imdbID == currentMovieID {
                                followingReviews.append(Review(imdbID: imdbID, criticID: criticID, body: body, score: score))
                            }
                        }
                        self.followingReviews = followingReviews
                        self.tableView.refreshControl?.endRefreshing()
                    })
                }
                self.tableView.refreshControl?.endRefreshing()
            }
        }
    }
    
    @IBAction func segmentChanged(_ sender: Any) {
        if segmentedControl.selectedSegmentIndex == 0 {
            self.reviews = []
        }
        else {
            self.followingReviews = []
        }
        refresh()

    }
        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segmentedControl.selectedSegmentIndex == 0 {
            return self.reviews.count
        }
        else {
            return self.followingReviews.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "movieInfoCell", for: indexPath) as! FeedTableViewCell
        if segmentedControl.selectedSegmentIndex == 0 {
            cell.review = self.reviews[indexPath.row]
        }
        else {
            cell.review = self.followingReviews[indexPath.row]
        }
        return cell

    }

    // Segue to Compose Review screen
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toCompose" {
            let composeVC = segue.destination as! ComposeTableViewController
            composeVC.imdbID = self.movieObject.imdbID
        }
        else if segue.identifier == "movieInfoExpandSegue", let nextVC = segue.destination as? ExpandedReviewTableViewController , let reviewIndex = tableView.indexPathForSelectedRow?.row {
            nextVC.deligate = self
            if segmentedControl.selectedSegmentIndex == 0 {
                nextVC.expanedReview = reviews[reviewIndex]
            }
            else {
                nextVC.expanedReview = followingReviews[reviewIndex]
            }
        }

    }
}
