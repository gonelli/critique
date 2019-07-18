//
//  ChatTableViewCell.swift
//  Critique
//
//  Created by Andrew Cramer on 7/18/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit

class ChatTableViewCell: UITableViewCell {

    var chat:Chat? {
        didSet {
            self.textLabel?.text = chat?.getTitle()
        }
    }

}
