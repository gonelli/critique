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
    
    @IBOutlet var plotLabel: UILabel!
    @IBOutlet var directorLabel: UILabel!
    @IBOutlet var yearLabel: UILabel!
    @IBOutlet var genreLabel: UILabel!
    
    @IBOutlet var updateButton: UIButton!
    @IBOutlet var posterImage: UIImageView!
    var movieTitle: String!
    var movieObject: Movie!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = movieTitle
        posterImage.image = movieObject.poster
        genreLabel.text = "Genre: \( movieObject.movieData["Genre"]!)"
        yearLabel.text = "Year: \( movieObject.movieData["Year"]!)"
        directorLabel.text = "Director: \( movieObject.movieData["Director"]!)"
        plotLabel.text = "Plot: \( movieObject.movieData["Plot"]!)"
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
