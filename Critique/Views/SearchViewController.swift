//
//  SearchViewController.swift
//  Critique
//
//  Created by Tony Gonelli on 7/2/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {
    
    let group = DispatchGroup()

    @IBOutlet var movieSearchButton: UIButton!
    @IBOutlet var movieSearchBar: UISearchBar!
    var movieList:Array<(String, Movie)> = Array<(String, Movie)>() {
        didSet {
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Search"
//        getMovieList(movieQuery: "star wars")
    }
    
    @IBAction func movieSearchPressed(_ sender: Any) {
        self.group.enter()  // i.e. semaphore up
        self.getMovieList(movieQuery: self.movieSearchBar.text!)
        group.notify(queue: .main) { // Wait for dispatch after async
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "movieSearchSegue", sender: sender)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "movieSearchSegue" {
            let resultVC = segue.destination as! SearchMovieResultsViewController
            resultVC.searchResults = self.movieList
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
