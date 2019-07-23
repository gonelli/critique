//
//  DummyDiscovery.swift
//  Critique
//
//  Created by Ameya Joshi on 7/23/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import Firebase
import FirebaseFirestore

class DummyDiscovery {
    
    var db: Firestore!
    
    var critics: [(String, Critic)] = [] // UID and Critic object tuples
    
    init() {
        initializeFirestore()
        getCritics()
    }
    
    func initializeFirestore() {
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        db = Firestore.firestore()
    }
    
    func getCritics() {
        var critics: [String: Critic] = [:]
        var usersBlocked: [String]!
        var usersFollowing: [String]!
        var usersFollowers: [String] = []
        let userID = Auth.auth().currentUser!.uid
        db.collection("users").getDocuments { (snapshot, error) in
            if error == nil {
                for document in snapshot!.documents {
                    let criticID = document.documentID
                    let data = document.data()
                    if data["isPublic"] as! Bool && !(data["blocked"] as! [String]).contains(userID) && criticID != userID {
                        critics[criticID] = Critic(name: data["name"] as! String, following: data["following"] as! [String])
                    }
                    else if criticID == userID {
                        usersFollowing = (data["following"] as! [String])
                        usersBlocked = (data["blocked"] as! [String])
                        usersBlocked.append(userID)
                    }
                }
                for blockedCritic in usersBlocked {
                    critics[blockedCritic] = nil
                }
                for (uid, follower) in critics {
                    for followedID in follower.following {
                        if let followed = critics[followedID] {
                            followed.followers.append(uid)
                        }
                        else if followedID == userID {
                            usersFollowers.append(uid)
                        }
                    }
                }
                for followedByUserID in usersFollowing {
                    if let followedByFollowedList = critics[followedByUserID]?.following {
                        for followedByFollowedID in followedByFollowedList {
                            critics[followedByFollowedID]?.weight += 10
                        }
                    }
                    if let followerOfFollowedList = critics[followedByUserID]?.followers {
                        for followerOfFollowedID in followerOfFollowedList {
                            critics[followerOfFollowedID]?.weight += 4
                            for followedByfollowerOfFollowedID in critics[followerOfFollowedID]?.following ?? [] {
                                critics[followedByfollowerOfFollowedID]?.weight += 2
                            }
                        }
                    }
                }
                for followerOfUserID in usersFollowers {
                    critics[followerOfUserID]?.weight += 3
                    for followedByFollowerID in critics[followerOfUserID]?.following ?? [] {
                        critics[followedByFollowerID]?.weight += 1
                    }
                }
                for followedByUserID in usersFollowing {
                    critics[followedByUserID] = nil
                }
                self.critics = critics.sorted(by: { $0.value > $1.value })
            }
            else {
                fatalError(error!.localizedDescription)
            }
        }
    }
    
}
