//
//  DummyReadTableViewController.swift
//  Critique
//
//  Created by James Jackson on 7/6/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

class DummyReadTableViewController: UITableViewController {
  
  var db: Firestore!

  override func viewDidLoad() {
    super.viewDidLoad()
    let settings = FirestoreSettings()
    Firestore.firestore().settings = settings
    db = Firestore.firestore()
    
    db.collection("users").document("\(Auth.auth().currentUser!.uid)").getDocument { (document, error) in
      
      print(Auth.auth().currentUser!.uid)
      
      let following = document?.data()!["following"] as! [String]
      
      for followed in following {
        self.db.collection("reviews").whereField("criticID", isEqualTo: followed).getDocuments(completion: { (snapshot, _) in
          for review in snapshot!.documents {
            print("\(review.documentID) => \(review.data())")
          }
        })
        }
      }
  }
}
