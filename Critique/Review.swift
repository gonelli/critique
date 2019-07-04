//
//  Review.swift
//  Critique
//
//  Created by Ameya Joshi on 7/2/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit

class Review {
    
    var poster: UIImage? // not in database, pulled when necessary
    var title: String? // stored as key to get info from OMDB
    var score: Double // stored as float
    var name: String // store user id, and get their public name
    var review: String // stored as string
    
    var movieID: String
    var userID: String
    var reviewID: String
    
    init(reviewID: String) {
        
    }
    
    func movieIDToTitle(movieID: String) {
        
    }
    
    func getPoster(movieID: String) {
        
    }
    
    func getName(userID: String) {
        
    }
    
    func getReview(reviewID: String) {
        
    }
    
}
