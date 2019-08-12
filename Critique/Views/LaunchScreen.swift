//
//  LaunchScreen.swift
//  Critique
//
//  Created by Tony Gonelli on 7/27/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

class LaunchScreen: UIViewController, CAAnimationDelegate {
    
    @IBOutlet var NameHider: UIImageView!
    @IBOutlet var CritiqueName: UIImageView!
    @IBOutlet var Popcorn: UIImageView!
    @IBOutlet var CqInitials: UIImageView!
    var reviews: [Review] = []
    var db: Firestore!
    var loggedIn: Bool! = false
    
    override func viewDidLoad() {
        if (Auth.auth().currentUser != nil) {
            self.loggedIn = true
            self.initializeFirestore()
            self.getReviews()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        usleep(100000) // 0.1 sec, buffer time
        self.spin1()
        self.moveName()
        self.movePopcorn()
    }
    
    func spin1() {
        UIView.animate(withDuration: 0.3, animations: {
            self.Popcorn.transform = CGAffineTransform(rotationAngle:  CGFloat.pi / -8)
            self.Popcorn.transform = CGAffineTransform(rotationAngle:  CGFloat.pi / -3)
            self.view.layoutIfNeeded()
        },
                       completion: { finished in
                        self.spin2()
        })
    }
    
    func spin2() {
        UIView.animate(
            withDuration: 0.2,
            animations: {
                self.Popcorn.transform =
                    self.Popcorn.transform.rotated(by: CGFloat(Double.pi / 3))
                self.view.layoutIfNeeded()
        },
            completion:{ finished in
                self.zoomPopcorn()
        }
        )
    }
    
    func moveName() {
        UIView.animate(
            withDuration: 0.4,
            animations: {
                self.CritiqueName.center.x -= self.view.center.x 
        },
            completion:{ finished in
                self.NameHider.isHidden = true
                self.CritiqueName.isHidden = true
        }
        )
    }
    
    func movePopcorn() {
        let distanceToMove = self.view.center.x - self.Popcorn.center.x
        
        UIView.animate(
            withDuration: 0.4,
            animations: {
                self.Popcorn.center.x += distanceToMove
        }
        )
        
        UIView.animate(
            withDuration: 0.4,
            animations: {
                self.CqInitials.center.x += distanceToMove
        }
        )
        
        UIView.animate(
            withDuration: 0.5,
            animations: {
                self.NameHider.center.x += distanceToMove
        }
        )
    }
    
    func zoomPopcorn() {
        UIView.animate(
            withDuration: 0.08,
            delay: 0.0,
            options: .curveEaseIn,
            animations: {
                self.Popcorn.transform = CGAffineTransform.identity.scaledBy(x: 0.8, y: 0.8) // Scale your image
        }) { finished in
            UIView.animate(withDuration: 0.08, animations: {
                self.Popcorn.transform = CGAffineTransform.identity
            })
        }
        
        UIView.animate(
            withDuration: 0.08,
            delay: 0.0,
            options: .curveEaseIn,
            animations: {
                self.CqInitials.transform = CGAffineTransform.identity.scaledBy(x: 0.8, y: 0.8) // Scale your image
        }) { finished in
            UIView.animate(withDuration: 0.08, animations: {
                self.CqInitials.transform = CGAffineTransform.identity
            }, completion: {finished in
                if (!self.loggedIn) {
                    self.performSegue(withIdentifier: "BootupLoginSegue", sender: self)
                }
                else {
                    self.goToFeed()
                }})
        }
    }
    
    func goToFeed() {
        self.performSegue(withIdentifier: "BootupFeedSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.Popcorn.isHidden = true
        self.CqInitials.isHidden = true
        
        if segue.identifier == "BootupFeedSegue" {
            let tabVC = segue.destination as! UITabBarController
            let navVC = tabVC.viewControllers![0] as! UINavigationController
            let feedVC = navVC.topViewController as! FeedTableViewController
            feedVC.reviews = self.reviews
        }
    }
    
    func initializeFirestore() {
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        db = Firestore.firestore()
    }
    
    func getReviews() {
        var reviews: [Review] = []
        var usersGotten = 0
        db.collection("users").document("\(Auth.auth().currentUser!.uid)").getDocument { (document, error) in
            if var following = document?.data()?["following"] as? [String] {
                if following.count == 0 {
                    self.reviews = []
                }
                following.append(Auth.auth().currentUser!.uid)
                for followed in following {
                    self.db.collection("reviews").whereField("criticID", isEqualTo: followed).getDocuments(completion: { (snapshot, _) in
                        for review in snapshot!.documents {
                            let body = review.data()["body"] as! String
                            let score = review.data()["score"] as! NSNumber
                            let criticID = review.data()["criticID"] as! String
                            let imdbID = review.data()["imdbID"] as! String
                            let likers = review.data()["liked"] as! [String]
                            let dislikers = review.data()["disliked"] as! [String]
                            let timestamp = review.data()["timestamp"] as! TimeInterval
                            reviews.append(Review(imdbID: imdbID, criticID: criticID, likers: likers, dislikers: dislikers, body: body, score: score, timestamp: timestamp, timeSort: true))
                        }
                        usersGotten += 1
                        if usersGotten == following.count {
                            self.reviews = reviews.sorted()
                        }
                    })
                }
            }
        }
    }
}
