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
        let nameSplit = name.uppercased().split(separator: " ")
        if nameSplit.count >= 2 {
            initialLabel.text = "\(Array(nameSplit[0])[0])\(Array(nameSplit[1])[0])"
        }
        initialBGView.backgroundColor = randomColor(seed: name.uppercased())
    }
    func randomColor(seed: String) -> UIColor {
        
        var total: Int = 0
        for u in seed.unicodeScalars {
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
