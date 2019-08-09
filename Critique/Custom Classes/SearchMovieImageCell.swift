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
    var movieObject: Movie!
    var group = DispatchGroup()
    
    func setCell(name: String, year: String, movie: Movie) {
        titleLabel.text = name
        yearLabel.text = "(" + year + ")"
    }
}
