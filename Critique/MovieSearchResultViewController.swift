//
//  MovieSearchResultViewController.swift
//  Critique
//
//  Created by Ameya Joshi on 7/4/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit

class MovieSearchResultViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let cellIdentifier = "movieSearchResultCell"
    let segueIdentifier = "searchToMovieInfoSegue"
    
    let searchResults: [(String, String)] = []
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // return the size of the specified section (default "section 0"
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath as IndexPath)
        let row = indexPath.row

        cell.textLabel?.text = searchResults[row].0
        
        return cell
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == segueIdentifier {
            let infoVC = segue.destination as! MovieInfoViewController
            let selectedRow = tableView.indexPathForSelectedRow!
            infoVC.movieTitle = searchResults[selectedRow.row].0
            
            // later need code to populate movie info page using info from using OMDB for movie with IMDB id searchResults[selectedRow.row].1
            
            tableView.deselectRow(at: selectedRow, animated: true)
        }
    }

}
