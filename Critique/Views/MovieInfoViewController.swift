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
import SafariServices

class MovieInfoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SFSafariViewControllerDelegate {
    
    @IBOutlet var imdbButton: UIButton!
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
    var reviews: [Review] = []
    var followingReviews: [Review] = []
    var scores: [Double] = []
    var tappedCriticID = ""
    var tappedCriticName = ""
    let composeSegue = "composeSegue"
    
    let critiqueRed = 0xe12b22
    
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
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Review", style: .done, target: self, action: #selector(self.post))
        
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if segmentedControl.selectedSegmentIndex == 0 {
            getReviews()
        }
        else {
            getFollowingReviews()
        }
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
    @IBAction func imdbButtonPressed(_ sender: Any) {
        // check if website exists
        guard let url = URL(string: "https://www.imdb.com/title/" + movieObject.imdbID) else {
            return
        }
        
        let safariVC = SFSafariViewController(url: url)
        present(safariVC, animated: true, completion: nil)
        safariVC.delegate = self
    }
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    // Fetches all reviews for this movie
    func getReviews() {
        var reviews: [Review] = []
        scores = []
        let currentMovieID = movieObject.movieData["imdbID"]!
        self.db.collection("reviews").whereField("imdbID", isEqualTo: currentMovieID).getDocuments(completion: { (snapshot, _) in
            //TODO: custom MovieInfoCell, not FeedTableViewCell
            if (snapshot!.documents.count == 0) {
                self.scoreLabel.text = "No scores"
                self.tableView.isUserInteractionEnabled = false
                self.reviews = []
                self.tableView.reloadData()
                self.tableView.refreshControl?.endRefreshing()
                self.tableView.isUserInteractionEnabled = true
            }
            var reviewsGotten = 0
            for review in snapshot!.documents {
                let body = review.data()["body"] as! String
                let score = review.data()["score"] as! NSNumber
                let timestamp = review.data()["timestamp"] as! TimeInterval
                self.scores.append(Double(truncating: score))
                let avgScore = ((self.scores.reduce(0, +) / Double(self.scores.count)) * pow(10.0, Double(2))
                    ).rounded() / pow(10.0, Double(2))
                self.scoreLabel.text = String(avgScore) + " / 10"
                
                let imdbID = review.data()["imdbID"] as! String
                let likers = review.data()["liked"] as! [String]
                let dislikers = review.data()["disliked"] as! [String]
                let criticID = review.data()["criticID"] as! String
                self.db.collection("users").document(criticID).getDocument() { (criticDocument, error) in
                    if error == nil {
                        let criticBlockList = criticDocument!.data()!["blocked"] as! [String]
                        self.db.collection("users").document(Auth.auth().currentUser!.uid).getDocument(completion: { (userDocument, error) in
                            if error == nil {
                                let userBlockList = userDocument!.data()!["blocked"] as! [String]
                                let criticIsPublic = criticDocument!.data()!["isPublic"] as! Bool
                                if criticIsPublic && !criticBlockList.contains(Auth.auth().currentUser!.uid) && !userBlockList.contains(criticID) {
                                    // TO-DO: Block around reviews
                                    reviews.append(Review(imdbID: imdbID, criticID: criticID, likers: likers, dislikers: dislikers, body: body, score: score, timestamp: timestamp, timeSort: false))
                                }
                                reviewsGotten += 1
                                if reviewsGotten == snapshot!.documents.count {
                                    self.tableView.isUserInteractionEnabled = false
                                    self.reviews = reviews.sorted()
                                    self.tableView.reloadData()
                                    self.tableView.refreshControl?.endRefreshing()
                                    self.tableView.isUserInteractionEnabled = true
                                }
                            }
                            else {
                                fatalError(error!.localizedDescription)
                            }
                        })
                    }
                    else {
                        fatalError("Unknown user")
                    }
                }
            }
        })
    }
    
    // Fetches reviews for this movie by critics the user is following
    func getFollowingReviews() {
        var followingReviews: [Review] = []
        let currentMovieID = movieObject.movieData["imdbID"] as! String
        
        db.collection("users").document("\(Auth.auth().currentUser!.uid)").getDocument { (document, error) in
            if var following = document?.data()?["following"] as? [String] {
                following.append(Auth.auth().currentUser!.uid)
                var criticsGotten = 0
                for followed in following {
                    self.db.collection("reviews").whereField("criticID", isEqualTo: followed).getDocuments(completion: { (snapshot, _) in
                        for review in snapshot!.documents {
                            let body = review.data()["body"] as! String
                            let score = review.data()["score"] as! NSNumber
                            let timestamp = review.data()["timestamp"] as! TimeInterval
                            let criticID = review.data()["criticID"] as! String
                            let likers = review.data()["liked"] as! [String]
                            let dislikers = review.data()["disliked"] as! [String]
                            let imdbID = review.data()["imdbID"] as! String
                            
                            if imdbID == currentMovieID {
                                followingReviews.append(Review(imdbID: imdbID, criticID: criticID, likers: likers, dislikers: dislikers, body: body, score: score, timestamp: timestamp, timeSort: false))
                            }
                        }
                        criticsGotten += 1
                        if criticsGotten == following.count {
                            self.tableView.isUserInteractionEnabled = false
                            self.followingReviews = followingReviews.sorted()
                            self.tableView.reloadData()
                            self.tableView.refreshControl?.endRefreshing()
                            self.tableView.isUserInteractionEnabled = true
                        }
                    })
                }
            }
        }
    }
    
    @IBAction func segmentChanged(_ sender: Any) {
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
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Fixes account page bottom cell issue ?????????????????
        let _ = tableView.dequeueReusableCell(withIdentifier: "movieInfoCell", for: indexPath) as! LikeDislikeCell
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "movieInfoCell", for: indexPath) as! LikeDislikeCell
        if segmentedControl.selectedSegmentIndex == 0 {
            cell.review = self.reviews[indexPath.row]
        }
        else {
            cell.review = self.followingReviews[indexPath.row]
        }
        
        let criticTap = ReviewCellTapGesture(target: self, action: #selector(self.handleTap(_:)))
        criticTap.criticID = cell.review!.criticID
        cell.criticLabel.addGestureRecognizer(criticTap)
        cell.criticLabel.isUserInteractionEnabled = true
        
        cell.selectionStyle = .none
        
        if (cell.review?.criticID == Auth.auth().currentUser?.uid) {
//            let critiqueRed = UIColor(red:0.88, green:0.17, blue:0.13, alpha:1.0)
//            cell.criticLabel.mixedTextColor = MixedColor(normal: critiqueRed.darker()!, night: critiqueRed.lighter()!)
        }
        
        return cell
    }
    
    @objc func handleTap(_ sender: ReviewCellTapGesture? = nil) {
        // Critic tapped
        
        self.tappedCriticID = sender!.criticID
        
        let criticNameGroup = DispatchGroup()
        criticNameGroup.enter()
        
        // Can't take name from label due to it not being set in cellForRowAt
        DispatchQueue.main.async {
            let ref = self.db.collection("users").document(self.tappedCriticID)
            ref.getDocument { (document, error) in
                if error == nil {
                    self.tappedCriticName = document!.data()!["name"] as! String
                    criticNameGroup.leave()
                }
                else {
                    fatalError(error!.localizedDescription)
                }
            }
        }
        
        criticNameGroup.notify(queue: .main) {
            self.performSegue(withIdentifier: "infoCriticSegue", sender: self)
        }
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
        else if segue.identifier == "infoCriticSegue" {
            let criticVC = segue.destination as! AccountViewController
            criticVC.accountID = self.tappedCriticID
            criticVC.accountName = self.tappedCriticName
        }
    }
}
