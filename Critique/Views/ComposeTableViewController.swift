//
//  ComposeTableViewController.swift
//  Critique
//
//  Created by James Jackson on 7/6/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

class ComposeTableViewController: UITableViewController {
    
    var db: Firestore!
    var imdbID: String!
    
    @IBOutlet weak var scoreTF: UITextField!
    @IBOutlet weak var reviewTV: UITextView!
    
    override func viewDidLoad() {
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        db = Firestore.firestore()
    }
    
    // Create a new review document in database after review is posted
    @IBAction func post(_ sender: Any) {
        if (Double(scoreTF.text!) == nil || reviewTV.text == "") {
            let alert = UIAlertController(title: "All Fields Required", message: "Fill in the score and review fields", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
        else if (Double(scoreTF.text!)! > 10  || Double(scoreTF.text!)! < 0) {
            let alert = UIAlertController(title: "Enter a Valid Score", message: "Scores can be any number from 0-10", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
        else if let currentUser = Auth.auth().currentUser {
            db.collection("reviews").document("\(currentUser.uid)_\(imdbID!)").setData([
                "criticID" : currentUser.uid,
                "imdbID" : imdbID as Any,
                "body" : reviewTV.text as Any,
                "score" : Double(scoreTF.text!) as Any
                ])
                _ = navigationController?.popViewController(animated: true)
        }
    }
}
