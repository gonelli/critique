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
    
    @IBOutlet weak var navItem: UINavigationItem!
    
    var movieTitle: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navItem.title = movieTitle
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == composeSegue {
            let composeVC = segue.destination as! ComposeReviewViewController
            composeVC.movieTitle = self.movieTitle
        }
    }

    @IBAction func backPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
