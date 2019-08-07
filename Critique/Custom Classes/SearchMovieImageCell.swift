//
//  SearchMovieImageCell.swift
//  Critique
//
//  Created by Tony Gonelli on 8/7/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit

class SearchMovieImageCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var yearLabel: UILabel!
    @IBOutlet weak var posterThumbnail: UIImageView!
    
    func setCell(name: String, year: String) {
        titleLabel.text = name
        yearLabel.text = "(" + year + ")"
    }
}
