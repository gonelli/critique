//
//  DummyViewController.swift
//  Critique
//
//  Created by James Jackson on 7/6/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit
import FirebaseAuth

class DummyViewController: UIViewController {

  @IBOutlet weak var loggedLabel: UILabel!
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if let currentUser = Auth.auth().currentUser {
      self.loggedLabel.text = "\(currentUser.email ?? "") logged in"
    } else {
      self.performSegue(withIdentifier: "toSignUp", sender: self)
    }
  }
}
