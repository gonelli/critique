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
import FirebaseFirestore
import FirebaseCore

class Chat {
    
    var db: Firestore!
    var messages: [MockMessage] = []
    var chatID: String
    var criticIDs: [String] = []
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
                for critic in self.criticIDs {
                    if critic != currentUser {
                        self.db.collection("users").document(critic).getDocument() { (document, error) in
                            if error == nil {
                                self.title = document?.data()!["name"] as! String
                            }
                        }
                    }
                }
              self.getMessages(completion: { (messages) in
              })
              
              self.getUserIDs(completion: { (ids) in
              })
            }
        }
    }
    
    func getTitle(completion: @escaping (String) -> Void) {
        db.collection("chats").document(chatID).getDocument() { (document, error) in
            if error == nil && Auth.auth().currentUser != nil {
                let currentUser = Auth.auth().currentUser!.uid
                self.title = currentUser
                for critic in self.criticIDs {
                    if critic != currentUser {
                        self.db.collection("users").document(critic).getDocument() { (document, error) in
                            if error == nil {
                                self.title = document?.data()!["name"] as! String
                                completion(self.title)
                                return
                            }
                        }
                    }
                }
            }
            completion(self.title)
        }
    }
    
    func getMessages(completion: @escaping ([MockMessage]) -> Void) {
        var messages: [MockMessage] = []
        db.collection("chats").document(chatID).getDocument() { (document, error) in
            if error == nil && Auth.auth().currentUser != nil {
              if let raw =  document?.data()?["messages"] as? [[String: Any]] {
                var i = 0
                for message in raw {
                  i += 1
                  let text = message["body"] as! String
                  let user = MockUser(senderId: "\(message["from"] as! Int)", displayName: "TODO")
                  let timestamp = (message["time"] as! Timestamp).dateValue()
                  messages.append(MockMessage(text: text, user: user, messageId: "\(i)", date: timestamp))
                }
                self.messages = messages
                completion(self.messages)
              }
            }
        }
    }
    
    func getUserIDs(completion: @escaping ([String]) -> Void) {
        db.collection("chats").document(chatID).getDocument() { (document, error) in
            if error == nil && Auth.auth().currentUser != nil {
                self.criticIDs = document?.data()!["users"] as! [String]
                completion(self.criticIDs)
            }
        }
    }
  
    func refresh(completion: @escaping () -> Void) {
        getMessages(completion: {_ in completion()})
    }
}
