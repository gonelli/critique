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
    @IBOutlet var initialLabel: UILabel!
    @IBOutlet var initialBgView: UIView!
    
    
    var snapshotListener:ListenerRegistration? = nil
    var delegate:UITableViewController! = nil
    var initialized:Bool = false
    
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
                
                // Avatar Initials
                self.initialLabel.text = "\(Array(title.uppercased())[0])"
                let nameSplit = title.uppercased().split(separator: " ")
                if nameSplit.count >= 2 {
                    self.initialLabel.text = "\(Array(nameSplit[0])[0])\(Array(nameSplit[1])[0])"
                }
                
                // Random Color
                self.initialBgView.backgroundColor = self.randomColor(seed: title.uppercased()).darker()
            }
            setSubtitleInfo()
            
            // Circles
            initialBgView.layer.cornerRadius = initialBgView.frame.size.width/2.0
            initialBgView.clipsToBounds = true
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
            timeFormatter.dateFormat = "h:mm a"
            timeFormatter.amSymbol = "AM"
            timeFormatter.pmSymbol = "PM"
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
        print("ADD LISTENER")
        self.initialized = false
        snapshotListener = chat?.getReference().addSnapshotListener() { _, _ in
            self.chat?.refresh {
                self.setSubtitleInfo()
                print("Listened")
                if self.delegate != nil && self.initialized {
                    (self.delegate as! MessagesListViewController).sortDMs()
                } else {
                    self.initialized = true
                }
            }
        }
    }
    
    func removeListener() {
        print("REMOVE LISTENER")
        if snapshotListener != nil{
            snapshotListener!.remove()
        }
    }
    
    // Source: https://gist.github.com/bendodson/bbb47acb3c31cdb6e87cdec72c63c7eb
    func randomColor(seed: String) -> UIColor {
        
        var total: Int = 0
        for u in (seed + "dHJ1bXAgZWF0cyBzaGl0").unicodeScalars {
            total += Int(UInt32(u))
        }
        
        srand48(total * 200)
        let r = CGFloat(drand48())
        
        srand48(total)
        let g = CGFloat(drand48())
        
        srand48(total / 200)
        let b = CGFloat(drand48())
        
        return UIColor(red: r, green: g, blue: b, alpha: 1)
    }

}
