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
    var messages: [MockMessage] = [] {
        didSet {
            for user in criticIDs {
                var userChats:[String] = []
                self.db.collection("users").document(user).getDocument(){ (document, error) in
                    if error == nil, let chatDoc = document {
                        userChats = chatDoc.data()!["myChats"] as! [String]
                        if !userChats.contains(self.chatID) {
                            userChats.append(self.chatID)
                            self.db.collection("users").document(user).setData(["myChats": userChats], merge: true)
                        }
                    }
                }
            }
        }
    }
    var chatID: String
    var criticIDs: [String] = []
    var title: String = ""
    var timestamp: Date? = nil
    
    init(_ chatID: String) {
        self.chatID = chatID
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        db = Firestore.firestore()
        self.getMessages() { messages in }
        self.getUserIDs() { ids in
            self.getTitle { title in }
        }
    }
    
    init(_ chatID: String, completion: @escaping () -> Void) {
        self.chatID = chatID
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        db = Firestore.firestore()
        self.getMessages() { messages in
            completion()
        }
        self.getUserIDs() { ids in
            self.getTitle { title in }
        }
    }
    
    func getTitle(completion: @escaping (String) -> Void) {
        db.collection("chats").document(chatID).getDocument() { (document, error) in
            if error == nil && Auth.auth().currentUser != nil {
                let currentUser = Auth.auth().currentUser!.uid
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
        }
    }
    
    func getMessages(completion: @escaping ([MockMessage]) -> Void) {
        //print("GET MESSAGES: \(messages.count)")
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
                if messages.count > 0 {
                    print("Made it here \(String(describing: self.timestamp))")
                    self.timestamp = messages[messages.count - 1].sentDate
                }
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
    
    func getTimestamp() -> Date? {
        return timestamp
    }
  
    func refresh(completion: @escaping () -> Void) {
        getMessages(completion: {_ in completion()})
    }
    
    func getReference() -> DocumentReference {
        return db.collection("chats").document(chatID)
    }
}
