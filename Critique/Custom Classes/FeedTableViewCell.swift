//
//  FeedTableViewCell.swift
//  Critique
//
//  Created by James Jackson on 7/6/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit
import Kingfisher
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

class FeedTableViewCell: UITableViewCell {
    
    @IBOutlet weak var movieLabel: UILabel!
    @IBOutlet weak var reviewLabel: UILabel!
    @IBOutlet weak var criticLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var posterImage: UIImageView!
  
    @IBOutlet weak var dislikeButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var likesLabel: UILabel!
  
    var db: Firestore!
  
    // A table cell in the Feed is defined by the Review it corresponds to
    var review: Review? {
        didSet {
            scoreLabel.text = "\(review!.score ?? 0)"
            if !scoreLabel.text!.contains(".") {
                scoreLabel.text = scoreLabel.text! + ".0"
            }
            reviewLabel.text = review?.body
            review?.getTitle(completion: { (title) in
                self.movieLabel.text = title
            })
            review?.getPosterURL(completion: { (posterURLString) in
                self.posterImage.kf.setImage(with: URL(string: posterURLString))
            })
            review?.getCritic(completion: { (critic) in
                self.criticLabel.text = critic
            })
            self.likeButton.setImage(UIImage(named: "like"), for: .normal)
            self.dislikeButton.setImage(UIImage(named: "dislike"), for: .normal)
            initializeFirestore()
            let movieID = review!.imdbID ?? "0"
            let criticID = review!.criticID ?? "0"
            let ref = self.db.collection("reviews").document(criticID + "_" + movieID)
            ref.getDocument { (document, error) in
              if error == nil {
                let liked = document!.data()!["liked"] as! [String]
                let disliked = document!.data()!["disliked"] as! [String]
                self.likesLabel.text = "\(liked.count - disliked.count)"
                let userID = Auth.auth().currentUser!.uid
                if liked.contains(userID) {
                  self.likeButton.setImage(UIImage(named: "liked"), for: .normal)
                  //self.dislikeButton.setImage(UIImage(named: "dislike"), for: .normal)
                } else if disliked.contains(userID) {
                  self.dislikeButton.setImage(UIImage(named: "disliked"), for: .normal)
                  //self.likeButton.setImage(UIImage(named: "like"), for: .normal)
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
  
  @IBAction func like(_ sender: Any) {
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
            self.likeButton.setImage(UIImage(named: "like"), for: .normal)
            liked.remove(at: index)
          }
        }
        else {
          if disliked.contains(userID) {
            if let index = disliked.firstIndex(of: userID) {
              self.dislikeButton.setImage(UIImage(named: "dislike"), for: .normal)
              disliked.remove(at: index)
            }
          }
          self.likeButton.setImage(UIImage(named: "liked"), for: .normal)
          liked.append(Auth.auth().currentUser!.uid)
        }
        ref.setData(["liked": liked], merge: true)
        ref.setData(["disliked": disliked], merge: true)
        self.likesLabel.text = "\(liked.count - disliked.count)"
      }
      else {
        fatalError(error!.localizedDescription)
      }
    }
    
  }
  
  @IBAction func dislike(_ sender: Any) {
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
            self.dislikeButton.setImage(UIImage(named: "dislike"), for: .normal)
            disliked.remove(at: index)
          }
        }
        else {
          if liked.contains(userID) {
            if let index = liked.firstIndex(of: userID) {
              self.likeButton.setImage(UIImage(named: "like"), for: .normal)
              liked.remove(at: index)
            }
          }
          self.dislikeButton.setImage(UIImage(named: "disliked"), for: .normal)
          disliked.append(Auth.auth().currentUser!.uid)
        }
        ref.setData(["liked": liked], merge: true)
        ref.setData(["disliked": disliked], merge: true)
        self.likesLabel.text = "\(liked.count - disliked.count)"
      }
      else {
        fatalError(error!.localizedDescription)
      }
    }
  }
  
}
