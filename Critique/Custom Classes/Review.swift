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
    var score: Double!
    var db: Firestore!
    var imdbID: String!
    var likers: [String]!
    var dislikers: [String]!
    var movieData: [String : Any]?
    var criticID: String!
    var timestamp: TimeInterval!
    var timeSort: Bool!
    
    init(imdbID: String, criticID: String, likers: [String], dislikers: [String], body: String, score: NSNumber, timestamp: TimeInterval, timeSort: Bool) {
        self.body = body
        self.score = Double(round(100 * (score as! Double)) / 100)
        self.imdbID = imdbID
        self.likers = likers
        self.dislikers = dislikers
        self.criticID = criticID
        self.timestamp = timestamp
        self.timeSort = timeSort
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
                    if let json = try! response.result.get() as? [String : Any] {
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

// Allows ordering reviews by date
extension Review: Comparable {
    
    static func < (lhs: Review, rhs: Review) -> Bool {
        if lhs.timeSort {
            return lhs.timestamp > rhs.timestamp
        }
        else {
            return (lhs.likers.count - lhs.dislikers.count) > (rhs.likers.count - rhs.dislikers.count)
        }
    }
    
    static func == (lhs: Review, rhs: Review) -> Bool {
        if lhs.timeSort {
            return lhs.timestamp == rhs.timestamp
        }
        else {
            return (lhs.likers.count - lhs.dislikers.count) == (rhs.likers.count - rhs.dislikers.count)
        }
    }
    
}
