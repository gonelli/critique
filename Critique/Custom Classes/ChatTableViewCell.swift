//
//  ChatTableViewCell.swift
//  Critique
//
//  Created by Andrew Cramer on 7/18/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit
import Firebase

class ChatTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    
    
    var snapshotListener:ListenerRegistration? = nil
    
    var chat:Chat? {
        didSet {
            
            guard chat != nil else {
                titleLabel.text = ""
                lastMessageLabel.text = ""
                timestampLabel.text = ""
                return
            }
            
            // Set cell parameters
            chat!.getTitle(){ (title) in
                self.titleLabel.text = title
                
            }
            
            setSubtitleInfo()
        }
    }
    
    func setSubtitleInfo() {
        chat!.getMessages() { messages in
            if messages.count > 0 {
                let lastMessage = messages[messages.count - 1]
                self.lastMessageLabel.text = lastMessage.text
                self.timestampLabel.text = self.getTimestampLabel(lastMessage.sentDate)
            } else {
                self.lastMessageLabel.text = ""
            }
        }
    }
    
    func getTimestampLabel(_ sentDate:Date) -> String {
        let minute:TimeInterval = 60.0
        let hour:TimeInterval = 60 * minute
        let day:TimeInterval = 24 * hour
        let week:TimeInterval = 7 * day
        
        var sentDateComponents: DateComponents? = Calendar.current.dateComponents([.hour, .minute, .second], from: sentDate)
        var currentDateComponents: DateComponents? = Calendar.current.dateComponents([.day, .month, .year], from: Date())
        currentDateComponents?.hour = sentDateComponents?.hour
        currentDateComponents?.minute = sentDateComponents?.minute
        currentDateComponents?.second = sentDateComponents?.second
        
        let timeDiff = Calendar.current.date(from: currentDateComponents!)!.timeIntervalSince(sentDate)
        if timeDiff < day {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            return timeFormatter.string(from: sentDate)
        } else if timeDiff < 2 * day {
            return "Yesterday"
        } else if timeDiff < week {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "EEEE"
            return timeFormatter.string(from: sentDate)
        } else {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "MM/dd/yy"
            return timeFormatter.string(from: sentDate)
        }
    }
    
    func setListener() {
        snapshotListener = chat?.getReference().addSnapshotListener() { _, _ in
            self.chat?.refresh {
                self.setSubtitleInfo()
            }
        }
    }
    
    func removeListener() {
        if snapshotListener != nil{
            snapshotListener!.remove()
        }
    }

}
