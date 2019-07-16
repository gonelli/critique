//
//  ExpandedReviewViewController.swift
//  Critique
//
//  Created by Andrew Cramer on 7/9/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit

class ExpandedReviewTableViewController: UITableViewController {
    
    @IBOutlet weak var movieLabel: UILabel!
    @IBOutlet weak var reviewTextView: UITextView!
    @IBOutlet weak var criticLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var posterImage: UIImageView!
    @IBOutlet weak var reviewCell: UITableViewCell!
    
    var deligate: UIViewController?
    var expanedReview: Review? = nil
    var movieObject: Movie? {
        didSet {
//            self.performSegue(withIdentifier: "expandedMovieInfoSegue", sender: self)
        }
    }
    
    // Fill in review's elements - movie title, poster, and critic name
    override func viewDidLoad() {
        super.viewDidLoad()
        
        reviewTextView.isScrollEnabled = false;
        
        if let review = expanedReview {
            scoreLabel.text = "\(review.score ?? 0)"
            reviewTextView.text = review.body
            
            review.getTitle(completion: { (title) in
                self.movieLabel.text = title
            })
            review.getPosterURL(completion: { (posterURLString) in
                self.posterImage.kf.setImage(with: URL(string: posterURLString))
            })
            review.getCritic(completion: { (critic) in
                self.criticLabel.text = critic
            })
        }
        
        let fixedWidth = reviewTextView.frame.size.width
        let newSize = reviewTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        reviewTextView.frame.size = CGSize(width: fixedWidth, height: newSize.height)
        
        let imagePath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: posterImage.frame.width, height: posterImage.frame.height - 30))
        reviewTextView.textContainer.exclusionPaths = [imagePath]
    
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        posterImage.addGestureRecognizer(tap)
        posterImage.isUserInteractionEnabled = true
        self.posterImage.addSubview(view)
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        let group = DispatchGroup()
        group.enter()
        
        DispatchQueue.main.async {
            self.movieObject = Movie(imdbId: self.expanedReview!.imdbID, outsideGroup: group, outsideGroupEntered: true)
        }
        group.notify(queue: .main) {
            self.performSegue(withIdentifier: "expandedMovieInfoSegue", sender: self)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return max(reviewTextView.contentSize.height + 70, posterImage.frame.height + posterImage.frame.minY + 10)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Segue to Movie Info page
        if segue.identifier == "expandedMovieInfoSegue" {
            let infoVC = segue.destination as! MovieInfoViewController
            infoVC.movieTitle = self.movieLabel.text
            infoVC.movieObject = self.movieObject
        }
    }
}

