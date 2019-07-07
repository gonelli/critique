//
//  Review.swift
//  Critique
//
//  Created by James Jackson on 7/6/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

class Review {

  var body: String!
  var score: NSNumber!
  
  var name: String! = "Test"
  var poster: UIImage!
  var title: String!
  
  var db: Firestore!
  
  
  init(imdbID: String, criticID: String, body: String, score: NSNumber) {
    
    self.body = body
    self.score = score
    
//    self.poster = getPoster(for: imdbID)
//    self.title = getTitle(for: imdbID)
//    self.name = getName(for: criticID)
    
    self.poster = UIImage(named: "icon-account")
    self.title = "imdb title"
    getName(for: criticID)
    


  }
  
  func getPoster(for imdbID: String) -> UIImage {
    return Movie(imdbId: "tt1825683").poster
  }
  
  func getTitle(for imdbID: String) -> String {
    //fix with a closure!
    return Movie(imdbId: "tt1825683").title
  }
  
  func getName(for criticID: String) {
    
    let settings = FirestoreSettings()
    Firestore.firestore().settings = settings
    db = Firestore.firestore()
    
    db.collection("users").document(criticID).getDocument { (user, error) in
      self.name = (user?.data()!["name"] as! String)
    }
  }

}
