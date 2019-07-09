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
    var accountName = "Unknown Name"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO: set name to Firebase username
        self.title = accountName
        // TODO: Popup action for Follow, Block, & Message.
        // Since the "..." would be covered on the left side by back button
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "...", style: .done, target: self, action: #selector(self.accountAction))
    }
    
    @objc func accountAction() {
        // When follow button pressed
    }
    
    
}
