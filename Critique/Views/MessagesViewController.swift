//
//  MessagesViewController.swift
//  Critique
//
//  Created by Tony Gonelli on 7/2/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

class MessagesViewController: UITableViewController {

    var db: Firestore!
    var directMessages: [Chat] = [] {
        didSet {
            self.tableView.reloadData() // Reload table after reviews are fetched
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Messages"
        addRefreshView()
        initializeFirestore()
//        getDirectMessages()
    }
    
    @objc func refresh() {
//        getDirectMessages()
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
//    func getDirectMessages() {
//        var reviews: [Review] = []
//        db.collection("users").document("\(Auth.auth().currentUser!.uid)").getDocument { (document, error) in
//            if let following = document?.data()?["following"] as? [String] {
//                for followed in following {
//                    self.db.collection("reviews").whereField("criticID", isEqualTo: followed).getDocuments(completion: { (snapshot, _) in
//                        for review in snapshot!.documents {
//                            let body = review.data()["body"] as! String
//                            let score = review.data()["score"] as! NSNumber
//                            let criticID = review.data()["criticID"] as! String
//                            let imdbID = review.data()["imdbID"] as! String
//                            reviews.append(Review(imdbID: imdbID, criticID: criticID, body: body, score: score))
//                        }
//                        self.directMessages = reviews
//                        self.tableView.refreshControl?.endRefreshing()
//                    })
//                }
//                self.tableView.refreshControl?.endRefreshing()
//            }
//        }
//    }
//
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return directMessages.count
//    }
//
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "feedCell", for: indexPath) as! FeedTableViewCell
//        cell.review = directMessages[indexPath.row]
//        return cell
//    }
//
//    // If body of a review is touched, open an expanded view of it
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//    }
}
