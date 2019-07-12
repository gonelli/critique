//
//  LoginViewController.swift
//  Critique
//
//  Created by Tony Gonelli on 7/2/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class LoginViewController: UITableViewController {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func signInPressed(_ sender: Any) {
        Auth.auth().signIn(withEmail: self.emailField.text!, password: self.passField.text!) { (result, error) in
            if error == nil {
                self.view.window!.rootViewController?.dismiss(animated: true, completion: {
                    let parent = ((UIApplication.shared.keyWindow?.rootViewController as! UITabBarController).viewControllers?.first as! UINavigationController?)?.viewControllers.first as! FeedTableViewController
                    parent.getReviews()
                })
            }
            else {
                let alert = UIAlertController(title: "Error", message: error!.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                self.present(alert, animated: true)
            }
        }
    }
    
    @IBAction func forgotPasswordPressed(_ sender: Any) {
        // Fill in dialog with email from TF
        var emailAddress:String? = ""
        let alert = UIAlertController(title: "Forgot Password", message: "Fill out the email below.  If there is an account with given email address, a new password will be sent.", preferredStyle: .alert)
        let action = UIAlertAction(title: "Send", style: .default) {
            (alertAction) in emailAddress = alert.textFields![0].text;
            if emailAddress != nil && emailAddress != "" {
                // Pass email back from dialog
                Auth.auth().sendPasswordReset(withEmail: emailAddress!) { error in
                    print("================================\n", "Forgot Password Error: ", error as Any, "\n================================")
                }
            }
        }
        alert.addTextField { (textField) in textField.text = self.emailField.text; textField.placeholder = "Enter your email";}
        alert.addAction(action)
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
