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
//            self.criticLabel.text = " "
            review?.getCritic(completion: { (critic) in
                self.scoreLabel.text = "\(self.review!.score ?? 0)"
                if !self.scoreLabel.text!.contains(".") {
                    self.scoreLabel.text = self.scoreLabel.text! + ".0"
                }
                self.reviewLabel.text = self.review?.body
                self.votesLabel.text = "\(self.review!.likers.count - self.review!.dislikers.count)"
                self.criticLabel.text = critic
                

            })
            self.upvoteButton.setImage(UIImage(named: "like"), for: .normal)
            self.downvoteButton.setImage(UIImage(named: "dislike"), for: .normal)
            self.initializeFirestore()
            let movieID = self.review!.imdbID ?? "0"
            let criticID = self.review!.criticID ?? "0"

            let ref = self.db.collection("reviews").document(criticID + "_" + movieID)
            ref.getDocument { (document, error) in
                if error == nil {
                    var liked = document!.data()!["liked"] as! [String]
                    var disliked = document!.data()!["disliked"] as! [String]
                    let userID = Auth.auth().currentUser!.uid
                    if liked.contains(userID) {
                        self.upvoteButton.setImage(UIImage(named: "liked"), for: .normal)
                        //self.downvoteButton.setImage(UIImage(named: "dislike"), for: .normal)
                    } else if disliked.contains(userID) {
                        self.downvoteButton.setImage(UIImage(named: "disliked"), for: .normal)
                        //self.upvoteButton.setImage(UIImage(named: "like"), for: .normal)
                    }
                    else {


                    }
                } else {
                    fatalError(error!.localizedDescription)
                }
            }

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
                        self.upvoteButton.setImage(UIImage(named: "like"), for: .normal)
                        liked.remove(at: index)
                    }
                }
                else {
                    if disliked.contains(userID) {
                        if let index = disliked.firstIndex(of: userID) {
                            self.downvoteButton.setImage(UIImage(named: "dislike"), for: .normal)
                            disliked.remove(at: index)
                        }
                    }
                    self.upvoteButton.setImage(UIImage(named: "liked"), for: .normal)
                    self.downvoteButton.setImage(UIImage(named: "dislike"), for: .normal)
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
                        self.downvoteButton.setImage(UIImage(named: "dislike"), for: .normal)
                        disliked.remove(at: index)
                    }
                }
                else {
                    if liked.contains(userID) {
                        if let index = liked.firstIndex(of: userID) {
                            self.upvoteButton.setImage(UIImage(named: "like"), for: .normal)
                            liked.remove(at: index)
                        }
                    }
                    self.downvoteButton.setImage(UIImage(named: "disliked"), for: .normal)
                    self.upvoteButton.setImage(UIImage(named: "like"), for: .normal)
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
