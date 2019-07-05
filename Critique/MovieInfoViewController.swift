//
//  MovieInfoViewController.swift
//  Critique
//
//  Created by Ameya Joshi on 7/4/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit

class MovieInfoViewController: UIViewController {
    
    let composeSegue = "composeSegue"
    
    @IBOutlet var updateButton: UIButton!
    @IBOutlet var posterImage: UIImageView!
    var movieTitle: String!
    var movieObject: Movie!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        posterImage.image = movieObject.poster
        
    }
    
    @IBAction func updateButtonPressed(_ sender: Any) {
        posterImage.image = movieObject.poster
    }
    
    /*
    override func viewWillAppear(_ animated: Bool) {
        navItem.title = movieTitle
    }*/
    
    /*
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == composeSegue {
            let composeVC = segue.destination as! ComposeReviewViewController
            composeVC.movieTitle = self.movieTitle
        }
    }*/
    

    
}
