//
//  FeedTableViewCell.swift
//  Critique
//
//  Created by James Jackson on 7/6/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit
import Kingfisher

class FeedTableViewCell: UITableViewCell {
    
    @IBOutlet weak var movieLabel: UILabel!
    @IBOutlet weak var reviewLabel: UILabel!
    @IBOutlet weak var criticLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var posterImage: UIImageView!
    
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
            

        }
    }
}
