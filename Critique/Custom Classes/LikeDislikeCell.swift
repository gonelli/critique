//
//  LikeDislikeCell.swift
//  Critique
//
//  Created by Tony Gonelli on 7/18/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit
import Kingfisher
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

class LikeDislikeCell: UITableViewCell {
    
    @IBOutlet weak var votesLabel: UILabel!
    @IBOutlet weak var upvoteButton: UIButton!
    @IBOutlet weak var downvoteButton: UIButton!
    @IBOutlet weak var criticLabel: UILabel!
    @IBOutlet weak var reviewLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    var db: Firestore!
    
    // A table cell in the Feed is defined by the Review it corresponds to
    var review: Review? {
        didSet {
            scoreLabel.text = "\(review!.score ?? 0)"
            reviewLabel.text = review?.body
            votesLabel.text = "\(review!.likers.count - review!.dislikers.count)"
            review?.getCritic(completion: { (critic) in
                self.criticLabel.text = critic
            })
            
            initializeFirestore()
        }
    }
    
    func initializeFirestore() {
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        db = Firestore.firestore()
    }

    @IBAction func upvotePressed(_ sender: Any) {
        let movieID = review!.imdbID ?? "0"
        let criticID = review!.criticID ?? "0"
        let ref = self.db.collection("reviews").document(criticID + "_" + movieID)
        ref.getDocument { (document, error) in
            if error == nil {
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
                self.votesLabel.text = "\(liked.count - disliked.count)"
            }
            else {
                fatalError(error!.localizedDescription)
            }
        }
    }
    @IBAction func downvotePressed(_ sender: Any) {
        let movieID = review!.imdbID ?? "0"
        let criticID = review!.criticID ?? "0"
        let ref = self.db.collection("reviews").document(criticID + "_" + movieID)
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
                self.votesLabel.text = "\(liked.count - disliked.count)"
            }
            else {
                fatalError(error!.localizedDescription)
            }
        }

    }
}
