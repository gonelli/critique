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
      
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Post", style: .done, target: self, action: #selector(self.post))
        
        tableView.delegate = self
        tableView.dataSource = self
        initializeFirestore()
        getReviews()
    }
    
    func initializeFirestore() {
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        db = Firestore.firestore()
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
                    let criticID = review.data()["criticID"] as! String
                    let imdbID = review.data()["imdbID"] as! String
                    reviews.append(Review(imdbID: imdbID, criticID: criticID, body: body, score: score))
                }
                self.reviews = reviews
                self.tableView.refreshControl?.endRefreshing()
            })
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.reviews.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "movieInfoCell", for: indexPath) as! FeedTableViewCell
        cell.review = self.reviews[indexPath.row]
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
            nextVC.expanedReview = reviews[reviewIndex]
        }

    }
}
