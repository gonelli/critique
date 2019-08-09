//
//  MockMessage.swift
//  Critique
//
//  Created by James Jackson on 8/9/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import Foundation
import MessageKit

struct MockMessage: MessageType, Comparable {
    
    var messageId: String
    var sender: SenderType {
        return user
    }
    var sentDate: Date
    var kind: MessageKind
    
    var user: MockUser
    
    var text: String = ""
    
    private init(kind: MessageKind, user: MockUser, messageId: String, date: Date) {
        self.kind = kind
        self.user = user
        self.messageId = messageId
        self.sentDate = date
    }
    
    init(text: String, user: MockUser, messageId: String, date: Date) {
        self.init(kind: .text(text), user: user, messageId: messageId, date: date)
        self.text = text
    }
    
    static func < (lhs: MockMessage, rhs: MockMessage) -> Bool {
        return lhs.sentDate < rhs.sentDate
    }
    
    static func == (lhs: MockMessage, rhs: MockMessage) -> Bool {
        return lhs.sentDate == rhs.sentDate
    }
    
}
