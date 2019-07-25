//
//  DiscoveryTableViewCell.swift
//  Critique
//
//  Created by Ameya Joshi on 7/25/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit

class DiscoveryTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var followLabel: UILabel!
    @IBOutlet weak var initialLabel: UILabel!
    @IBOutlet weak var initialBGView: UIView!
    
    func setCell(name: String, followers: Int, following: Int) {
        nameLabel.text = name
        followLabel.text = "Followers: \(followers) Following: \(following)"
        initialLabel.text = "\(Array(name.uppercased())[0])"
    }

}
