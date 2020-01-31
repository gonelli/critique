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

class CreateAccountTableViewController: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var usernameTF: UITextField!
    @IBOutlet weak var emailTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    @IBOutlet weak var confirmPasswordTF: UITextField!
    var algoliaId = "noid"
    var algoliaKey = "nokey"
    
    var db: Firestore!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let keys = appDelegate.keys
        algoliaId = keys?["algoliaId"] as? String ?? "noid"
        algoliaKey = keys?["algoliaKey"] as? String ?? "nokey"
        
        usernameTF.delegate = self
        emailTF.delegate = self
        passwordTF.delegate = self
        confirmPasswordTF.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(SearchViewController.dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
        initFirestore()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
                        "following": [] as [String],
                        "blocked": [] as [String],
                        "myChats": [] as [String]
                    ]){ (error) in
                        let client = Client(appID: self.algoliaId, apiKey: self.algoliaKey)
                        client.index(withName: "users").addObject(["name": self.usernameTF.text!, "objectID": user!.user.uid])
                        Auth.auth().signIn(withEmail: self.emailTF.text!, password: self.passwordTF.text!)
                    }
                    let storyboard = UIStoryboard(name:"Main", bundle: nil)
                    let vc = storyboard.instantiateInitialViewController()!
                    self.present(vc, animated: true, completion: nil)

//                    self.view.window!.rootViewController?.dismiss(animated: false, completion: {
//                        //                    let parent = ((UIApplication.shared.keyWindow?.rootViewController as! UITabBarController).viewControllers?.first as! UINavigationController?)?.viewControllers.first as! FeedTableViewController
//                        let parent = (UIApplication.shared.keyWindow?.rootViewController as! LaunchScreen)
//                        parent.goToFeed()
//                    })
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
    
    @IBAction func cancelPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // code to dismiss keyboard when user clicks on background
    func textFieldShouldReturn(_ textField:UITextField) -> Bool {
        if (textField == usernameTF) {
            emailTF.becomeFirstResponder()
        }
        else if (textField == emailTF) {
            passwordTF.becomeFirstResponder()
        }
        else if (textField == passwordTF) {
            confirmPasswordTF.becomeFirstResponder()
        }
        else {
            textField.resignFirstResponder()
            signUp(self)
        }
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
}
