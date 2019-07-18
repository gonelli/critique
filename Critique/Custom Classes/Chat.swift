//
//  Chat.swift
//  Critique
//
//  Created by Andrew Cramer on 7/16/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import Alamofire

class Chat {
    
    var db: Firestore!
    var messages: [[String:Any]] = []
    var chatID: String
    var criticiDs: [String] = []
    var title: String
    
    init(_ chatID: String) {
        self.chatID = chatID
        self.title = chatID
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        db = Firestore.firestore()
        db.collection("chats").document(chatID).getDocument() { (document, error) in
            if error == nil && Auth.auth().currentUser != nil {
                let currentUser = Auth.auth().currentUser!.uid
                self.title = currentUser
                for critic in self.criticiDs {
                    if critic != currentUser {
                        self.db.collection("users").document(critic).getDocument() { (document, error) in
                            if error == nil {
                                self.title = document?.data()!["name"] as! String
                            }
                        }
                    }
                }
                self.messages = document?.data()!["messages"] as! [[String:Any]]
                self.criticiDs = document?.data()!["users"] as! [String]
            }
            print("ChatID: \(self.chatID)\nTitle: \(self.title)\nCriticIDs: \(self.criticiDs)\nMessages: \(self.messages)")
        }
    }
}
