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
    var messages: String = ""
    var chatID: String
    var criticiDs: [String] = []
    
    init(_ chatID: String) {
        self.chatID = chatID
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        db = Firestore.firestore()
    }
}
