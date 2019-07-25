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
import InstantSearchClient

class CreateAccountTableViewController: UITableViewController {
    
    @IBOutlet weak var usernameTF: UITextField!
    @IBOutlet weak var emailTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    @IBOutlet weak var confirmPasswordTF: UITextField!
    
    var db: Firestore!
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(SearchViewController.dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
        initFirestore()
    }
    
    func initFirestore() {
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        db = Firestore.firestore()
    }
    
    // Attempt to create an account for user, and automatically sign them in if successful
    @IBAction func signUp(_ sender: Any) {
        if emailTF.text != nil && emailTF.text != "" && passwordTF.text == confirmPasswordTF.text {
            emailTF.text = emailTF.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            Auth.auth().createUser(withEmail: emailTF.text!, password: passwordTF.text!) {
                user, error in
                if error == nil {
                    // Create a document for each user in the database
                    self.db.collection("users").document((user?.user.uid)!).setData([
                        "isPublic" : true,
                        "name" : self.usernameTF.text!,
                        "following": [user!.user.uid] as [String],
                        "blocked": [] as [String],
                        "myChats": [] as [String]
                    ]){ (error) in
                        let client = Client(appID: "3PCPRD2BHV", apiKey: "e2ab8935cad696d6a4536600d531097b")
                        client.index(withName: "users").addObject(["name": self.usernameTF.text!, "objectID": user!.user.uid])
                        Auth.auth().signIn(withEmail: self.emailTF.text!, password: self.passwordTF.text!)
                    }
                    self.dismiss(animated: true, completion: {
                        // code for refreshing on sign in
                        let parent = ((UIApplication.shared.keyWindow?.rootViewController as! UITabBarController).viewControllers?.first as! UINavigationController?)?.viewControllers.first as! FeedTableViewController
                        parent.getReviews()
                    })
                }
                // Error on singing up
                else {
                    let alert = UIAlertController(title: "Error", message: error!.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                    self.present(alert, animated: true)
                }
            }
        } // User did not fill sign up form
        else if passwordTF.text == confirmPasswordTF.text {
            let alert = UIAlertController(title: "Error", message: "Fill in all required fields.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
            self.present(alert, animated: true)
        } // Passwords do not match
        else {
            let alert = UIAlertController(title: "Error", message: "Passwords do not match.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // code to dismiss keyboard when user clicks on background
    func textFieldShouldReturn(textField:UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
}
