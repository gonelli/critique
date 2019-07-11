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
    
    @IBOutlet var yearLabel: UILabel!
    @IBOutlet var synopsisTextView: UITextView!
    @IBOutlet var updateButton: UIButton!
    @IBOutlet var posterImage: UIImageView!
    var movieTitle: String!
    var movieObject: Movie!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = movieTitle
        posterImage.image = movieObject.poster
        synopsisTextView.text = movieObject.movieData["Plot"]! as? String
        synopsisTextView.isEditable = false
        posterImage.layer.masksToBounds = true
        posterImage.layer.borderWidth = 0
        posterImage.layer.borderColor = UIColor.lightGray.cgColor
        yearLabel.text = " \( movieObject.movieData["Year"]!)"
        yearLabel.textColor = UIColor.gray
      
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Post", style: .done, target: self, action: #selector(self.post))
//      self.navigationController?.navigationBar.topItem?.rightBarButtonItem = post
      
    }
  
  @objc func post() {
    performSegue(withIdentifier: "toCompose", sender: self)
  }
    
    @IBAction func updateButtonPressed(_ sender: Any) {
        posterImage.image = movieObject.poster
    }
    
    /*
    override func viewWillAppear(_ animated: Bool) {
        navItem.title = movieTitle
    }*/
    
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "toCompose" {
      let composeVC = segue.destination as! ComposeTableViewController
      composeVC.imdbID = self.movieObject.imdbID
    }
  }
}
