//
//  ExpandedReviewViewController.swift
//  Critique
//
//  Created by Andrew Cramer on 7/9/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit


class ExpandedReviewTableViewController: UITableViewController {

    
    //    @IBOutlet weak var movieLabel: UILabel!
    @IBOutlet weak var movieLabel: UILabel!
    //    @IBOutlet weak var reviewLabel: UILabel!
    @IBOutlet weak var reviewTextView: UITextView!
    //    @IBOutlet weak var criticLabel: UILabel!
    @IBOutlet weak var criticLabel: UILabel!
    //    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    //    @IBOutlet weak var posterImage: UIImageView!
    @IBOutlet weak var posterImage: UIImageView!
    
    //@IBOutlet var tableView: UITableView!
    @IBOutlet weak var reviewCell: UITableViewCell!
    
    
    var deligate: UIViewController?
    var expanedReview: Review? = nil
    
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
        
        
        // Find the lowest object then calculate and set the bounding height to that
        print("Frame height: ",reviewTextView.frame.height)
        print("Contents height:", reviewTextView.contentSize.height)
        
        let fixedWidth = reviewTextView.frame.size.width
        let newSize = reviewTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        reviewTextView.frame.size = CGSize(width: fixedWidth, height: newSize.height)
        
        //reviewTextView.frame.size = CGSize(width: reviewTextView.contentSize.width, height: reviewTextView.contentSize.height)
        
        print("Frame height: ",reviewTextView.frame.height)
        print("Contents height:", reviewTextView.contentSize.height)
        
        //let leftMargin = UIBezierPath(rect: CGRect(x: 0, y: 0, width: 20, height: reviewCell.bounds.height))
        
        let imagePath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: posterImage.frame.width, height: posterImage.frame.height - 30))
        reviewTextView.textContainer.exclusionPaths = [imagePath]
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        //reviewTextView.frame.height = reviewTextView.contentSize.height
        return max(reviewTextView.contentSize.height + 70, posterImage.frame.height + posterImage.frame.minY + 10)
    }
}
