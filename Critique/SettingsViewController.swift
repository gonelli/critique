//
//  SettingsViewController.swift
//  Critique
//
//  Created by Tony Gonelli on 7/2/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {
    
    @IBOutlet var NameChangeCell: UITableViewCell!
    @IBOutlet var BlockedCell: UITableViewCell!
    @IBOutlet var PublicCell: UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Settings"
        
        BlockedCell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        NameChangeCell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
    }
    
    
}
