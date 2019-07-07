//
//  CreateAccountTableViewController.swift
//  Critique
//
//  Created by James Jackson on 7/6/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class CreateAccountTableViewController: UITableViewController {
  
  var db: Firestore!
  
  @IBOutlet weak var usernameTF: UITextField!
  @IBOutlet weak var emailTF: UITextField!
  @IBOutlet weak var passwordTF: UITextField!
  @IBOutlet weak var confirmPasswordTF: UITextField!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    initFirestore()
  }
  
  func initFirestore() {
    let settings = FirestoreSettings()
    Firestore.firestore().settings = settings
    db = Firestore.firestore()
  }
  
  @IBAction func signUp(_ sender: Any) {
    if emailTF.text != nil && emailTF.text != "" && passwordTF.text == confirmPasswordTF.text {
      emailTF.text = emailTF.text!.trimmingCharacters(in: .whitespacesAndNewlines)
      Auth.auth().createUser(withEmail: emailTF.text!, password: passwordTF.text!) {
        user, error in
        if error == nil {
          let changeRequest = user?.user.createProfileChangeRequest()
          changeRequest?.displayName = self.usernameTF.text
          changeRequest?.commitChanges(completion: nil)
          Auth.auth().signIn(withEmail: self.emailTF.text!, password: self.passwordTF.text!)
          
          self.db.collection("users").document((user?.user.uid)!).setData([
            "isPublic" : true
            ])
          
          self.dismiss(animated: true, completion: {
            // code for refrshing on sign in
            let parent = ((UIApplication.shared.keyWindow?.rootViewController as! UITabBarController).viewControllers?.first as! UINavigationController?)?.viewControllers.first as! FeedTableViewController
            parent.getReviews()
          })
        } else {
          print("================================\n", "Error: ",error as Any, "\n================================")
          let alert = UIAlertController(title: "Unknown Error", message: (error as! String?) ?? "nil", preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
          self.present(alert, animated: true)
        }
      }
    } else if passwordTF.text == confirmPasswordTF.text {
      let alert = UIAlertController(title: "Missing requited fields", message: "Make sure all required text fields are filled.", preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
      self.present(alert, animated: true)
    } else {
      let alert = UIAlertController(title: "Passwords do not match", message: "Make sure that Password and ConfirmPassword match.", preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
      self.present(alert, animated: true)
    }
  }
  
}
