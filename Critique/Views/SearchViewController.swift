//
//  SearchViewController.swift
//  Critique
//
//  Created by Tony Gonelli on 7/2/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit
import InstantSearchClient
import FirebaseFirestore
import FirebaseAuth

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var movieList:Array<(String, Movie)> = Array<(String, Movie)>() // list of movie results - tuple stores name and Movie object
    var criticList: [(String, String)] = [] // list of critic results - tuple stores name and UID
    let group = DispatchGroup()
    
    let client = Client(appID: "3PCPRD2BHV", apiKey: "e2ab8935cad696d6a4536600d531097b") // Algolia client
    let cellIdentifier = "searchResultCell"
    let movieInfoSegue = "movieInfoSegue"
    let criticProfileSegue = "criticProfileSegue"
    
    var db: Firestore!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Search"
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        initFirestore()
    }
    
    func initFirestore() {
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        db = Firestore.firestore()
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segmentedControl.selectedSegmentIndex == 0 {
            return self.movieList.count
        }
        else {
            return self.criticList.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath as IndexPath)
        let row = indexPath.row
        
        if segmentedControl.selectedSegmentIndex == 0 {
            cell.textLabel?.text = movieList[row].0
        }
        else {
            cell.textLabel?.text = criticList[row].0
        }
        
        return cell
    }
    
    // Take user to Movie Info or Profile page after they touch a cell
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if segmentedControl.selectedSegmentIndex == 0 {
            performSegue(withIdentifier: movieInfoSegue, sender: self)
        }
        else {
            performSegue(withIdentifier: criticProfileSegue, sender: self)
        }
    }
    
    // Reset search results and reload on a segment change
    @IBAction func segmentChanged(_ sender: Any) {
        if segmentedControl.selectedSegmentIndex == 0 {
            criticList = []
        }
        else {
            movieList = Array<(String, Movie)>()
        }
        searchBarSearchButtonClicked(searchBar)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Segue to Movie Info page
        if segue.identifier == movieInfoSegue {
            let infoVC = segue.destination as! MovieInfoViewController
            let selectedRow = tableView.indexPathForSelectedRow!
            infoVC.movieTitle = self.movieList[selectedRow.row].0
            infoVC.movieObject = self.movieList[selectedRow.row].1
            
            tableView.deselectRow(at: selectedRow, animated: true)
        }
        // Segue to Profile page
        else if segue.identifier == criticProfileSegue {
            let profileVC = segue.destination as! AccountViewController
            let selectedRow = tableView.indexPathForSelectedRow!
            profileVC.accountName = self.criticList[selectedRow.row].0
            profileVC.accountID = self.criticList[selectedRow.row].1
            
            tableView.deselectRow(at: selectedRow, animated: true)
        }
        else {
            fatalError("Unknown segue identifier")
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
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        // Search for movie
        if segmentedControl.selectedSegmentIndex == 0 {
            self.group.enter()  // i.e. semaphore up
            self.getMovieList(movieQuery: self.searchBar.text!)
            group.notify(queue: .main) { // Wait for dispatch after async
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
            // Search for critic
        else {
            self.criticList = []
            if searchBar.text! != "" {
                client.index(withName: "users").search(Query(query: searchBar.text!)) { (content, error) in
                    if error == nil {
                        guard let hits = content!["hits"] as? [[String: AnyObject]] else { fatalError("Hits is not a json") }
                        var hitsSearched = 0
                        for hit in hits {
                            var hitPublic = true
                            var userBlocked = false
                            var hitBlocked = false
                            var checksDone = 0 {
                                didSet {
                                    if checksDone == 2 {
                                        if hitPublic && !userBlocked && !hitBlocked {
                                            self.criticList.append((hit["name"] as! String, hit["objectID"] as! String))
                                        }
                                        hitsSearched += 1
                                        if hitsSearched == hits.count {
                                            self.tableView.reloadData()
                                        }
                                    }
                                }
                            }
                            self.db.collection("users").document(hit["objectID"] as! String).getDocument() { (document, error) in
                                if error == nil {
                                    hitPublic = document!.data()!["isPublic"] as! Bool
                                    if hitPublic {
                                        let hitBlockedList = document!.data()!["blocked"] as! [String]
                                        userBlocked = hitBlockedList.contains(Auth.auth().currentUser!.uid)
                                    }
                                    checksDone += 1
                                }
                                else {
                                    fatalError(error!.localizedDescription)
                                }
                            }
                            self.db.collection("users").document(Auth.auth().currentUser!.uid).getDocument() { (document, error) in
                                if error == nil {
                                    let userBlockedList = document!.data()!["blocked"] as! [String]
                                    hitBlocked = userBlockedList.contains(hit["objectID"] as! String)
                                    checksDone += 1
                                }
                                else {
                                    fatalError(error!.localizedDescription)
                                }
                            }
                        }
                    }
                    else {
                        fatalError(error!.localizedDescription)
                    }
                }
            }
        }
    }

    // Gets search results for a movie query using the OMDB API
    func getMovieList(movieQuery: String) {
        let unallowedUrlString = "http://www.omdbapi.com/?s=" + movieQuery + "&apikey=" + "7cc21a66"
        let allowedUrlString = unallowedUrlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        if let url = URL(string: allowedUrlString!) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    if String(data: data, encoding: .utf8) != nil {
                        do {
                            // Results from OMDB are in JSON format
                            let movieNSDict : NSDictionary = try JSONSerialization.jsonObject(with: data, options: []) as! NSDictionary
                            
                            DispatchQueue.main.async {
                                if let movieDict = movieNSDict as? [String: Any] {
                                    let search: Array<Dictionary<String, Any>> = movieDict["Search"] as? Array<Dictionary<String, Any>> ?? Array<Dictionary<String, Any>>()
                                    
                                    var titleList = Array<(String, Movie)>()
                                    for movie in search {
                                        let mediaType: String = movie["Type"]! as! String
                                        if mediaType != "movie" { // Ignore TV shows
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
