//
//  ExpandedReviewViewController.swift
//  Critique
//
//  Created by Andrew Cramer on 7/9/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit
import Firebase
import NightNight

class ExpandedReviewTableViewController: UITableViewController {
    
    @IBOutlet weak var movieLabel: UILabel!
    @IBOutlet weak var reviewTextView: UITextView!
    @IBOutlet weak var criticLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var posterImage: UIImageView!
    @IBOutlet weak var reviewCell: UITableViewCell!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var dislikeButton: UIButton!
    @IBOutlet weak var likesLabel: UILabel!
  
    var deligate: UIViewController?
    var expanedReview: Review? = nil
    var movieObject: Movie?
    var tappedCriticID: String?
    var tappedCriticName: String?
    let mixedNightBgColor = MixedColor(normal: 0xffffff, night: 0x222222)
    let mixedNightTextColor = MixedColor(normal: 0x000000, night: 0xdddddd)
    let mixedNightFadedTextColor = MixedColor(normal: 0x777777, night: 0xaaaaaa)
  
    var db: Firestore!
    
    // Fill in review's elements - movie title, poster, critic name, etc.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        reviewTextView.isScrollEnabled = false;
        
        if let review = expanedReview {
            scoreLabel.text = "\(review.score ?? 0)"
            if !scoreLabel.text!.contains(".") {
                scoreLabel.text = scoreLabel.text! + ".0"
            }
            reviewTextView.text = review.body
            
            review.getTitle(completion: { (title) in
                self.movieLabel.text = title
            })
            review.getPosterURL(completion: { (posterURLString) in
                self.posterImage.kf.setImage(with: URL(string: posterURLString))
            })
            review.getCritic(completion: { (critic) in
                self.criticLabel.text = critic
                let criticTap = ReviewCellTapGesture(target: self, action: #selector(self.handleExpandedTap(_:)))
                criticTap.criticID = review.criticID
                if review.criticID == Auth.auth().currentUser!.uid {
                    let critiqueRed = UIColor(red:0.88, green:0.17, blue:0.13, alpha:0.7)
                    self.criticLabel.mixedTextColor = MixedColor(normal: critiqueRed.darker(by: 25)!, night: critiqueRed.lighter(by: 25)!)
                }
                self.criticLabel.addGestureRecognizer(criticTap)
                self.criticLabel.isUserInteractionEnabled = true
            })
        }
        
        let fixedWidth = reviewTextView.frame.size.width
        let newSize = reviewTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        reviewTextView.frame.size = CGSize(width: fixedWidth, height: newSize.height)
        
        let imagePath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: posterImage.frame.width + 10, height: posterImage.frame.height - 30))
        reviewTextView.textContainer.exclusionPaths = [imagePath]
    
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        posterImage.addGestureRecognizer(tap)
        posterImage.isUserInteractionEnabled = true
        self.posterImage.addSubview(view)
        
        // NightNight
        tableView.mixedBackgroundColor = MixedColor(normal: 0xefeff4, night: 0x161616)
        reviewCell.mixedBackgroundColor = mixedNightBgColor
        reviewCell.mixedTintColor = mixedNightTextColor
        reviewTextView.mixedBackgroundColor = mixedNightBgColor
        reviewTextView.mixedTintColor = mixedNightTextColor // borders above and below
        reviewTextView.mixedTextColor = mixedNightTextColor
        criticLabel.mixedTextColor = mixedNightFadedTextColor
        likesLabel.mixedTextColor = mixedNightFadedTextColor
        scoreLabel.mixedTextColor = mixedNightTextColor
        movieLabel.mixedTextColor = mixedNightTextColor
        
        initializeFirestore()
        let movieID = expanedReview!.imdbID ?? "0"
        let criticID = expanedReview!.criticID ?? "0"
        let ref = self.db.collection("reviews").document(criticID + "_" + movieID)
        ref.getDocument { (document, error) in
          if error == nil {
            let liked = document!.data()!["liked"] as! [String]
            let disliked = document!.data()!["disliked"] as! [String]
            self.likesLabel.text = "\(liked.count - disliked.count)"
            let userID = Auth.auth().currentUser?.uid
            if liked.contains(userID ?? "") {
              self.likeButton.setImage(UIImage(named: "liked"), for: .normal)
              self.dislikeButton.setMixedImage(MixedImage(normal: UIImage(named: "dislike")!, night: UIImage(named: "dislike-white")!), forState: .normal)
            } else if disliked.contains(userID ?? "") {
              self.likeButton.setMixedImage(MixedImage(normal: UIImage(named: "like")!, night: UIImage(named: "like-white")!), forState: .normal)
              self.dislikeButton.setImage(UIImage(named: "disliked"), for: .normal)
            } else {
              self.likeButton.setMixedImage(MixedImage(normal: UIImage(named: "like")!, night: UIImage(named: "like-white")!), forState: .normal)
              self.dislikeButton.setMixedImage(MixedImage(normal: UIImage(named: "dislike")!, night: UIImage(named: "dislike-white")!), forState: .normal)
            }
          } else {
            fatalError(error!.localizedDescription)
          }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // NightNight exception
        if (NightNight.theme == .night) {
            self.navigationController!.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(red:0.87, green:0.87, blue:0.87, alpha:1.0)]
        }
        else {
            self.navigationController!.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        }
    }
    
    // If movie poster is pressed, show the movie's info
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        let group = DispatchGroup()
        group.enter()
        
        DispatchQueue.main.async {
            self.movieObject = Movie(imdbId: self.expanedReview!.imdbID, outsideGroup: group, outsideGroupEntered: true)
        }
        group.notify(queue: .main) {
            self.performSegue(withIdentifier: "expandedMovieInfoSegue", sender: self)
            print(self.movieObject?.movieData["Title"])
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return max(reviewTextView.frame.height + self.likeButton.frame.height + 60, posterImage.frame.height + posterImage.frame.origin.y + 60)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @objc func handleExpandedTap(_ sender: ReviewCellTapGesture? = nil) {
        self.tappedCriticID = sender!.criticID
        self.tappedCriticName = self.criticLabel.text!
        performSegue(withIdentifier: "expandedCriticSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Segue to Movie Info page
        if segue.identifier == "expandedMovieInfoSegue" {
            let infoVC = segue.destination as! MovieInfoViewController
            infoVC.movieTitle = self.movieLabel.text
            infoVC.movieObject = self.movieObject
        }
        else if segue.identifier == "expandedCriticSegue" {
            let criticVC = segue.destination as! AccountViewController
            criticVC.accountID = self.tappedCriticID!
            criticVC.accountName = self.tappedCriticName!
        }
    }
  
  @IBAction func like(_ sender: Any) {
    let movieID = expanedReview!.imdbID ?? "0"
    let criticID = expanedReview!.criticID ?? "0"
    let ref = self.db.collection("reviews").document(criticID + "_" + movieID)
    ref.getDocument { (document, error) in
      if error == nil {
        var liked = document!.data()!["liked"] as! [String]
        var disliked = document!.data()!["disliked"] as! [String]
        let userID = Auth.auth().currentUser!.uid
        if liked.contains(userID) {
          if let index = liked.firstIndex(of: userID) {
            self.likeButton.setMixedImage(MixedImage(normal: UIImage(named: "like")!, night: UIImage(named: "like-white")!), forState: .normal)
            self.dislikeButton.setMixedImage(MixedImage(normal: UIImage(named: "dislike")!, night: UIImage(named: "dislike-white")!), forState: .normal)
            liked.remove(at: index)
          }
        }
        else {
          if disliked.contains(userID) {
            if let index = disliked.firstIndex(of: userID) {
              disliked.remove(at: index)
            }
          }
          self.likeButton.setImage(UIImage(named: "liked"), for: .normal)
          self.dislikeButton.setMixedImage(MixedImage(normal: UIImage(named: "dislike")!, night: UIImage(named: "dislike-white")!), forState: .normal)
          liked.append(userID)
        }
        ref.setData(["liked": liked, "disliked": disliked], merge: true)
        self.likesLabel.text = "\(liked.count - disliked.count)"
      }
      else {
        fatalError(error!.localizedDescription)
      }
    }
  }
  
  @IBAction func dislike(_ sender: Any) {
    let movieID = expanedReview!.imdbID ?? "0"
    let criticID = expanedReview!.criticID ?? "0"
    let ref = self.db.collection("reviews").document(criticID + "_" + movieID)
    ref.getDocument { (document, error) in
      if error == nil {
        // When follow pressed
        var liked = document!.data()!["liked"] as! [String]
        var disliked = document!.data()!["disliked"] as! [String]
        let userID = Auth.auth().currentUser!.uid
        
        if disliked.contains(userID) {
          if let index = disliked.firstIndex(of: userID) {
            self.likeButton.setMixedImage(MixedImage(normal: UIImage(named: "like")!, night: UIImage(named: "like-white")!), forState: .normal)
            self.dislikeButton.setMixedImage(MixedImage(normal: UIImage(named: "dislike")!, night: UIImage(named: "dislike-white")!), forState: .normal)
            disliked.remove(at: index)
          }
        }
        else {
          if liked.contains(userID) {
            if let index = liked.firstIndex(of: userID) {
              liked.remove(at: index)
            }
          }
          self.likeButton.setMixedImage(MixedImage(normal: UIImage(named: "like")!, night: UIImage(named: "like-white")!), forState: .normal)
          self.dislikeButton.setImage(UIImage(named: "disliked"), for: .normal)
          disliked.append(userID)
        }
        ref.setData(["liked": liked, "disliked": disliked], merge: true)
        self.likesLabel.text = "\(liked.count - disliked.count)"
      }
      else {
        fatalError(error!.localizedDescription)
      }
    }
  }
  
  
  func initializeFirestore() {
    let settings = FirestoreSettings()
    Firestore.firestore().settings = settings
    db = Firestore.firestore()
  }
  
}

