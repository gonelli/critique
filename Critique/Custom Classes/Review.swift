//
//  Review.swift
//  Critique
//
//  Created by James Jackson on 7/6/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import Alamofire

class Review {

    var body: String!
    var score: NSNumber!
    var db: Firestore!
    var imdbID: String!
    var likers: [String]!
    var dislikers: [String]!
    var movieData: [String : Any]?
    var criticID: String!
    var timestamp: TimeInterval!
    
    init(imdbID: String, criticID: String, likers: [String], dislikers: [String], body: String, score: NSNumber, timestamp: TimeInterval) {
        self.body = body
        self.score = score
        self.imdbID = imdbID
        self.likers = likers
        self.dislikers = dislikers
        self.criticID = criticID
        self.timestamp = timestamp
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        db = Firestore.firestore()
    }
    
    // Fetch movie info in JSON format given an IMDB id
    func getMovieData(completion: @escaping ([String : Any]) -> Void) {
        if let movieData = movieData {
            completion(movieData)
        }
        else {
            if let url = URL(string: "http://www.omdbapi.com/?i=\(imdbID ?? "")&apikey=7cc21a66") {
                AF.request(url).responseJSON { (response) in
                    if let json = response.result.value as? [String : Any] {
                        self.movieData = json
                        completion(json)
                    }
                }
            }
        }
    }
    
    func getTitle(completion: @escaping (String) -> Void) {
        getMovieData { (data) in
            completion(data["Title"] as! String)
        }
    }
    
    func getPosterURL(completion: @escaping (String) -> Void) {
        getMovieData { (data) in
            completion(data["Poster"] as! String)
        }
    }
    
    func getCritic(completion: @escaping (String) -> Void) {
        db.collection("users").document(self.criticID).getDocument { (snapshot, error) in
            completion(snapshot?.data()!["name"] as! String)
        }
    }
    
}

extension Review: Comparable {
    
    static func < (lhs: Review, rhs: Review) -> Bool {
        return lhs.timestamp > rhs.timestamp
    }
    
    static func == (lhs: Review, rhs: Review) -> Bool {
        return lhs.timestamp == rhs.timestamp
    }
    
}
