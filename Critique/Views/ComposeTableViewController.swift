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
    
    @IBAction func post(_ sender: Any) {
        if let currentUser = Auth.auth().currentUser {
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
