//
//  SearchViewController.swift
//  Critique
//
//  Created by Tony Gonelli on 7/2/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let cellIdentifier = "movieSearchResultCell"
    let segueIdentifier = "movieInfoSegue"
    
    @IBOutlet var movieSearchButton: UIButton!
    @IBOutlet var movieSearchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    let group = DispatchGroup()
    
    var movieList:Array<(String, Movie)> = Array<(String, Movie)>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Search"
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    @IBAction func movieSearchPressed(_ sender: Any) {
        self.group.enter()  // i.e. semaphore up
        self.getMovieList(movieQuery: self.movieSearchBar.text!)
        group.notify(queue: .main) { // Wait for dispatch after async
            DispatchQueue.main.async {
                //                self.performSegue(withIdentifier: "movieSearchSegue", sender: sender)
                self.tableView.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movieList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath as IndexPath)
        let row = indexPath.row
        
        cell.textLabel?.text = movieList[row].0
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: segueIdentifier, sender: self)
    }
    
    //    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    //        if segue.identifier == "movieSearchSegue" {
    //            let resultVC = segue.destination as! SearchMovieResultsViewController
    //            resultVC.searchResults = self.movieList
    //        }
    //    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == segueIdentifier {
            
            let infoVC = segue.destination as! MovieInfoViewController
            let selectedRow = tableView.indexPathForSelectedRow!
            infoVC.movieTitle = self.movieList[selectedRow.row].0
            infoVC.movieObject = self.movieList[selectedRow.row].1
            // later need code to populate movie info page using info from using OMDB for movie with IMDB id searchResults[selectedRow.row].1
            
            tableView.deselectRow(at: selectedRow, animated: true)
        }
    }
    
    // code to dismiss keyboard when user clicks on background
    
    func textFieldShouldReturn(textField:UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func getMovieList(movieQuery: String) {
        let unallowedUrlString = "http://www.omdbapi.com/?s=" + movieQuery + "&apikey=" + "7cc21a66"
        let allowedUrlString = unallowedUrlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        if let url = URL(string: allowedUrlString!) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    if String(data: data, encoding: .utf8) != nil {
                        do {
                            let movieNSDict : NSDictionary = try JSONSerialization.jsonObject(with: data, options: []) as! NSDictionary
                            
                            DispatchQueue.main.async {
                                if let movieDict = movieNSDict as? [String: Any] {
                                    let search: Array<Dictionary<String, Any>> = movieDict["Search"] as? Array<Dictionary<String, Any>> ?? Array<Dictionary<String, Any>>()
                                    
                                    var titleList = Array<(String, Movie)>()
                                    for movie in search {
                                        let mediaType: String = movie["Type"]! as! String
                                        if mediaType != "movie" {
                                            continue
                                        }
                                        titleList.append((movie["Title"]! as! String, Movie(imdbId: movie["imdbID"] as! String)))
                                    }
                                    self.movieList = titleList
                                }
                                self.group.leave()  // async done, i.e. sema down
                            }
                        }
                        catch {
                        }
                    }
                }
                else {
                    print("Data nil")
                }
                }.resume()
        }
    }
}
