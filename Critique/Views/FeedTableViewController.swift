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
//  private let refreshControl = UIRefreshControl()
  
  var reviews: [Review] = [] {
    didSet {
      self.tableView.reloadData()
    }
  }
    
  // SegueIDs
  let expandedReviewSegueID = "expandedReviewSegueID"
  
  override func viewDidLoad() {
    super.viewDidLoad()
//    try! Auth.auth().signOut()
    addRefreshView()
    initializeFirestore()
    if (Auth.auth().currentUser != nil) {
      getReviews()
    }
  }
  
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
    
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == expandedReviewSegueID, let nextVC = segue.destination as? ExpandedReviewTableViewController , let reviewIndex = tableView.indexPathForSelectedRow?.row {
      nextVC.deligate = self
      nextVC.expanedReview = reviews[reviewIndex]
    }
  }
  
}
