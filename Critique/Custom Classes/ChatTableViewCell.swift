//
//  ChatTableViewCell.swift
//  Critique
//
//  Created by Andrew Cramer on 7/18/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit

class ChatTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    
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
    }
    
    func getTimestampLabel(_ sentDate:Date) -> String {
        let minute:TimeInterval = 60.0
        let hour:TimeInterval = 60 * minute
        let day:TimeInterval = 24 * hour
        let week:TimeInterval = 7 * day
        
        let timeDiff = sentDate.timeIntervalSinceNow
        
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

}
