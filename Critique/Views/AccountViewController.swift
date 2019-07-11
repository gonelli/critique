//
//  AccountViewController.swift
//  Critique
//
//  Created by Tony Gonelli on 7/2/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit
import Foundation

class AccountViewController: UIViewController {
    
    @IBOutlet var accountTabLabel: UILabel!
    
    var accountName = "(Account Name)"
    var accountID = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO: set name to Firebase username
        self.title = accountName
        // TODO: Popup action for Follow, Block, & Message.
        // Since the "..." would be covered on the left side by back button
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "...", style: .done, target: self, action: #selector(self.accountAction))
    }
    
    @objc func accountAction() {
        let controller = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet)
        
        let blockAction = UIAlertAction(
            title: "Block",
            style: .destructive
        )
        
        let messageAction = UIAlertAction(
            title: "Message",
            style: .default
        )
        
        let followAction = UIAlertAction(
            title: "Follow",
            style: .default
        )
        
        let cancelAction = UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: { (action) in print("Cancel Action")}
        )
        
        messageAction.setValue(UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0), forKey: "titleTextColor")
        followAction.setValue(UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0), forKey: "titleTextColor")
        cancelAction.setValue(UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0), forKey: "titleTextColor")
        
        
        controller.addAction(followAction)
        controller.addAction(messageAction)
        controller.addAction(blockAction)
        controller.addAction(cancelAction)
        
        present(controller, animated: true, completion: nil)
    }
    
    
}
