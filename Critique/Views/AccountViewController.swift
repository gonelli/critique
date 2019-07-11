//
//  AccountViewController.swift
//  Critique
//
//  Created by Tony Gonelli on 7/2/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import UIKit
import Foundation

class AccountViewController: UIViewController {
    
    var db: Firestore!
    @IBOutlet var accountTabLabel: UILabel!
    
    var accountName = ""
    var accountID = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO: set name to Firebase username
        // TODO: Popup action for Follow, Block, & Message.
        // Since the "..." would be covered on the left side by back button
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "•••", style: .done, target: self, action: #selector(self.accountAction))
        initializeFirestore()
        
        if accountName == "" {
            accountID = "\(Auth.auth().currentUser!.uid)"
            db.collection("users").document(accountID).getDocument() { (document, error) in
                if error == nil {
                    self.accountName = document!.data()!["name"] as! String
                    self.title = self.accountName
                } else {
                    fatalError(error!.localizedDescription)
                }
            }
        } else {
            self.title = accountName
        }
    }
    
    func initializeFirestore() {
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        db = Firestore.firestore()
    }

    @objc func accountAction() {
        let controller = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet)
        
        let blockAction = UIAlertAction(
            title: "Block",
            style: .destructive,
            handler:  {(alert) in
                let ref = self.db.collection("users").document("\(Auth.auth().currentUser!.uid)")
                ref.getDocument { (document, error) in
                    if error == nil {
                        // When blocked button pressed
                        var blocked = document!.data()!["blocked"] as! [String]
                        blocked.append(self.accountID)
                        var following = document!.data()!["following"] as! [String]
                        following.removeAll { $0 == self.accountID }
                        ref.setData(["blocked": blocked], merge: true)
                        ref.setData(["following": following], merge: true)
                    }
                    else {
                        fatalError(error!.localizedDescription)
                    }
                }
            }
        )
        
        let unblockAction = UIAlertAction(
            title: "Unblock",
            style: .destructive,
            handler:  {(alert) in
                let ref = self.db.collection("users").document("\(Auth.auth().currentUser!.uid)")
                ref.getDocument { (document, error) in
                    if error == nil {
                        // When blocked button pressed
                        var blocked = document!.data()!["blocked"] as! [String]
                        blocked.removeAll { $0 == self.accountID }
                        ref.setData(["blocked": blocked], merge: true)
                    }
                    else {
                        fatalError(error!.localizedDescription)
                    }
                }
        }
        )
        
        let messageAction = UIAlertAction(
            title: "Message",
            style: .default
        )
        
        let ref = self.db.collection("users").document("\(Auth.auth().currentUser!.uid)")
        
        let followAction = UIAlertAction(
            title: "Follow",
            style: .default,
            handler: {(alert) in
                ref.getDocument { (document, error) in
                    if error == nil {
                        // When follow button pressed
                        var following = document!.data()!["following"] as! [String]
                        following.append(self.accountID)
                        ref.setData(["following": following], merge: true)
                    }
                    else {
                        fatalError(error!.localizedDescription)
                    }
                }
            }
        )
        
        let unfollowAction = UIAlertAction(
            title: "Unfollow",
            style: .default,
            handler: {(alert) in
                ref.getDocument { (document, error) in
                    if error == nil {
                        // When unfollow button pressed
                        var following = document!.data()!["following"] as! [String]
                        following.removeAll { $0 == self.accountID }
                        ref.setData(["following": following], merge: true)
                    }
                    else {
                        fatalError(error!.localizedDescription)
                    }
                }
            }
        )
        
        let cancelAction = UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: { (action) in print("Cancel Action")}
        )
        
        messageAction.setValue(UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0), forKey: "titleTextColor")
        unfollowAction.setValue(UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0), forKey: "titleTextColor")
        followAction.setValue(UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0), forKey: "titleTextColor")
        cancelAction.setValue(UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0), forKey: "titleTextColor")
        
        ref.getDocument { (document, error) in
            if error == nil {
                let following = document!.data()!["following"] as! [String]
                let blocked = document!.data()!["blocked"] as! [String]
                if following.contains(self.accountID) && self.accountID != Auth.auth().currentUser!.uid {
                    controller.addAction(unfollowAction)
                }
                else if (self.accountID != Auth.auth().currentUser!.uid) {
                    controller.addAction(followAction)
                }
                controller.addAction(messageAction)
                if blocked.contains(self.accountID) {
                    controller.addAction(unblockAction)
                }
                else {
                    controller.addAction(blockAction)
                }
            }
            else {
                fatalError(error!.localizedDescription)
            }
        }
        
        controller.addAction(cancelAction)
        
        present(controller, animated: true, completion: nil)
    }
    
    
}
