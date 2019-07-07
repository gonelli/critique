//
//  FeedTableViewCell.swift
//  Critique
//
//  Created by James Jackson on 7/6/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit

class FeedTableViewCell: UITableViewCell {
  
  @IBOutlet weak var movieLabel: UILabel!
  @IBOutlet weak var reviewLabel: UILabel!
  @IBOutlet weak var criticLabel: UILabel!
  @IBOutlet weak var scoreLabel: UILabel!
  @IBOutlet weak var posterImage: UIImageView!
  
  var review: Review? {
    didSet {
      movieLabel.text = review?.title
      reviewLabel.text = review?.body
      criticLabel.text = review?.name
      scoreLabel.text = "\(review!.score ?? 0)"
      posterImage.image = review?.poster
    }
  }
}
