//
//  FeedViewController.swift
//  Critique
//
//  Created by Tony Gonelli on 7/2/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit

class FeedViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Feed"
        
        let rightButtonItem = UIBarButtonItem.init(
            title: "Post",
            style: .done,
            target: self,
            action: Selector(("rightButtonAction:"))
        )
        
        self.navigationItem.rightBarButtonItem = rightButtonItem
        
    }
    
    
}
