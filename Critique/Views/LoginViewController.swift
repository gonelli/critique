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
import NightNight

class LoginViewController: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passField: UITextField!
    let mixedNightBgColor = MixedColor(normal: 0xffffff, night: 0x222222)
    let mixedNightTextColor = MixedColor(normal: 0x000000, night: 0xdddddd)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailField.delegate = self
        passField.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(SearchViewController.dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
        
        // NightNight
        self.navigationController!.navigationBar.mixedBarTintColor = MixedColor(normal: UIColor(red: 0.969, green: 0.969, blue: 0.969, alpha: 1.0), night: UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0))
        self.navigationController!.navigationBar.mixedBarStyle = MixedBarStyle(normal: .default, night: .black)
        emailField.mixedTextColor = mixedNightTextColor
        emailField.mixedBackgroundColor = mixedNightBgColor
        passField.mixedTextColor = mixedNightTextColor
        passField.mixedBackgroundColor = mixedNightBgColor
        
        if(NightNight.theme == .night) { // Idk but it works to fix statusbar color
            NightNight.theme = .night
        }
        else {
            NightNight.theme = .normal
        }
        
        tableView.mixedBackgroundColor = MixedColor(normal: 0xefeff4, night: 0x161616)
        tableView.mixedTintColor = MixedColor(normal: UIColor.red, night: UIColor.red)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if(NightNight.theme == .night) {
            self.navigationController!.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(red:0.87, green:0.87, blue:0.87, alpha:1.0)]
            emailField.attributedPlaceholder = NSAttributedString(string: "Email", attributes: [NSAttributedString.Key.foregroundColor: UIColor(red:0.41, green:0.41, blue:0.42, alpha:1.0)])
            emailField.keyboardAppearance = .dark
            passField.attributedPlaceholder = NSAttributedString(string: "Password", attributes: [NSAttributedString.Key.foregroundColor: UIColor(red:0.41, green:0.41, blue:0.42, alpha:1.0)])
            passField.keyboardAppearance = .dark
            
        }
        else {
            self.navigationController!.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
            emailField.attributedPlaceholder = NSAttributedString(string: "Email", attributes: [NSAttributedString.Key.foregroundColor: UIColor(red:0.78, green:0.78, blue:0.80, alpha:1.0)])
            emailField.keyboardAppearance = .default
            passField.attributedPlaceholder = NSAttributedString(string: "Password", attributes: [NSAttributedString.Key.foregroundColor: UIColor(red:0.78, green:0.78, blue:0.80, alpha:1.0)])
            passField.keyboardAppearance = .default
        }
    }
    
    // Attempt to sign in after button is pressed
    @IBAction func signInPressed(_ sender: Any) {
        Auth.auth().signIn(withEmail: self.emailField.text!, password: self.passField.text!) { (result, error) in
            if error == nil {
                self.dismiss(animated: true, completion: {
                    // code for refreshing on sign in
                    //                        let parent = ((UIApplication.shared.keyWindow?.rootViewController as! UITabBarController).viewControllers?.first as! UINavigationController?)?.viewControllers.first as! FeedTableViewController
                    //                        parent.getReviews()
                    let parent = (UIApplication.shared.keyWindow?.rootViewController as! LaunchScreen)
                    parent.goToFeed()
                })
            }
                // Error while signing in
            else {
                let alert = UIAlertController(title: "Error", message: error!.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                self.present(alert, animated: true)
            }
        }
    }
    
    // Send a password reset email if the user forgot their password
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.mixedBackgroundColor = mixedNightBgColor
    }
    
    // code to dismiss keyboard when user clicks on background
    func textFieldShouldReturn(_ textField:UITextField) -> Bool {
        if (textField == emailField) {
            passField.becomeFirstResponder()
        }
        else {
            textField.resignFirstResponder()
            signInPressed(self)
        }
        
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }
    // TO-DO: Remove me
}
