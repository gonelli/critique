//
//  ExpandedReviewViewController.swift
//  Critique
//
//  Created by Andrew Cramer on 7/9/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit
import NightNight

class ExpandedReviewTableViewController: UITableViewController {
    
    @IBOutlet weak var movieLabel: UILabel!
    @IBOutlet weak var reviewTextView: UITextView!
    @IBOutlet weak var criticLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var posterImage: UIImageView!
    @IBOutlet weak var reviewCell: UITableViewCell!
    
    var deligate: UIViewController?
    var expanedReview: Review? = nil
    var movieObject: Movie?
    let mixedNightBgColor = MixedColor(normal: 0xffffff, night: 0x222222)
    let mixedNightTextColor = MixedColor(normal: 0x000000, night: 0xdddddd)
    
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
        
        // NightNight
        tableView.mixedBackgroundColor = MixedColor(normal: 0xefeff4, night: 0x111111)
        reviewCell.mixedBackgroundColor = mixedNightBgColor
        reviewCell.mixedTintColor = mixedNightTextColor
        reviewTextView.mixedBackgroundColor = mixedNightBgColor
        reviewTextView.mixedTintColor = mixedNightTextColor // borders above and below
        reviewTextView.mixedTextColor = mixedNightTextColor
        criticLabel.mixedTextColor = mixedNightTextColor
        scoreLabel.mixedTextColor = mixedNightTextColor
        movieLabel.mixedTextColor = mixedNightTextColor
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
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return max(reviewTextView.contentSize.height + 70, posterImage.frame.height + posterImage.frame.minY + 10)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
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

