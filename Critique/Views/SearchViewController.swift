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
    @IBOutlet weak var discoveryTableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var movieList:Array<(String, Movie)> = Array<(String, Movie)>() // list of movie results - tuple stores name and Movie object
    var criticList: [(String, String)] = [] // list of critic results - tuple stores name and UID
    var critics: [(String, Critic)] = []
    let group = DispatchGroup()
    
    var client : Client!
    let cellIdentifier = "searchResultCell"
    let movieInfoSegue = "movieInfoSegue"
    let criticProfileSegue = "criticProfileSegue"
    let critiqueRed = 0xe12b22
    var omdbApiKey = "nokey"
    
    var db: Firestore!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Search"
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let keys = appDelegate.keys
        let algoliaId = keys?["algoliaId"] as? String ?? "noid"
        let algoliaKey = keys?["algoliaKey"] as? String ?? "nokey"
        omdbApiKey = keys?["omdbApiKey"] as? String ?? "nokey"
        client = Client(appID: algoliaId, apiKey: algoliaKey) // Algolia client
        
        tableView.delegate = self
        tableView.dataSource = self
        discoveryTableView.delegate = self
        discoveryTableView.dataSource = self
        searchBar.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(SearchViewController.dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
        tableView.isHidden = true
        segmentedControl.isHidden = true
        self.navigationItem.title = "Discovery"
        discoveryTableView.refreshControl = UIRefreshControl()
        discoveryTableView.refreshControl!.addTarget(self, action: #selector(refresh), for: .valueChanged)
        initFirestore()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getCritics()
    }
    
    func initFirestore() {
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        db = Firestore.firestore()
    }
    
    @objc func refresh() {
        getCritics()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn, animations: {
            self.searchBar.showsCancelButton = true
            self.tableView.isHidden = false
            self.segmentedControl.isHidden = false
            self.discoveryTableView.isHidden = true
            self.navigationItem.title = "Search"
        })
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // Stop doing the search stuff
        // and clear the text in the search bar
        searchBar.text = ""
        // Hide the cancel button
        // You could also change the position, frame etc of the searchBar
        searchBar.endEditing(true)
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
            self.searchBar.showsCancelButton = false
            self.tableView.isHidden = true
            self.segmentedControl.isHidden = true
            self.discoveryTableView.isHidden = false
            self.navigationItem.title = "Discovery"
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.tableView {
            if segmentedControl.selectedSegmentIndex == 0 {
                return self.movieList.count
            }
            else {
                return self.criticList.count
            }
        }
        else {
            return self.critics.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == self.tableView {
            let row = indexPath.row
            
            if segmentedControl.selectedSegmentIndex == 0 {
                let movieCell = tableView.dequeueReusableCell(withIdentifier: "movieCell", for: indexPath as IndexPath) as! SearchMovieImageCell
                movieCell.titleLabel?.text = movieList[row].0
                movieCell.posterThumbnail.image = movieList[row].1.poster
                movieCell.movieObject = movieList[row].1
                movieList[row].1.movieCell = movieCell
                
                movieCell.selectionStyle = .none
                return movieCell
            }
            else {
                let criticCell = tableView.dequeueReusableCell(withIdentifier: "criticCell", for: indexPath as IndexPath) as! DiscoveryTableViewCell
                criticCell.setCell(name: criticList[row].0, followers: 0, following: 0, uid: criticList[row].1)
                criticCell.followLabel.text = ""
                
                criticCell.selectionStyle = .none
                return criticCell
            }
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "discoveryCell", for: indexPath as IndexPath) as! DiscoveryTableViewCell
            let critic = critics[indexPath.row].1
            
            cell.setCell(name: critic.name!, followers: critic.followers.count, following: critic.following.count, uid: critics[indexPath.row].0)
            
            cell.selectionStyle = .none
            return cell
        }
    }
    
    // Take user to Movie Info or Profile page after they touch a cell
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == self.tableView {
            if segmentedControl.selectedSegmentIndex == 0 {
                performSegue(withIdentifier: movieInfoSegue, sender: self)
            }
            else {
                performSegue(withIdentifier: criticProfileSegue, sender: self)
            }
        }
        else {
            performSegue(withIdentifier: "discoverySegue", sender: self)
        }
    }
    
    // Reset search results and reload on a segment change
    @IBAction func segmentChanged(_ sender: Any) {
        if segmentedControl.selectedSegmentIndex == 0 {
            self.tableView.isUserInteractionEnabled = false
            criticList = []
            tableView.reloadData()
            self.tableView.isUserInteractionEnabled = true
        }
        else {
            self.tableView.isUserInteractionEnabled = false
            movieList = Array<(String, Movie)>()
            tableView.reloadData()
            self.tableView.isUserInteractionEnabled = true
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
        else if segue.identifier == "discoverySegue" {
            let profileVC = segue.destination as! AccountViewController
            let selectedRow = discoveryTableView.indexPathForSelectedRow!
            profileVC.accountName = self.critics[selectedRow.row].1.name!
            profileVC.accountID = self.critics[selectedRow.row].0
            
            discoveryTableView.deselectRow(at: selectedRow, animated: true)
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
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
            self.searchBar.showsCancelButton = false
            self.tableView.isHidden = true
            self.segmentedControl.isHidden = true
            self.discoveryTableView.isHidden = false
            self.navigationItem.title = "Discovery"
        })
    }
    
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
        //        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
        //            self.searchBar.showsCancelButton = false
        //            self.tableView.isHidden = true
        //            self.segmentedControl.isHidden = true
        //            self.discoveryTableView.isHidden = false
        //            self.navigationItem.title = "Discovery"
        //        })
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        // Search for movie
        if segmentedControl.selectedSegmentIndex == 0 {
            self.group.enter()  // i.e. semaphore up
            self.movieList = Array<(String, Movie)>() // Clear results page
            self.getMovieList(movieQuery: self.searchBar.text!)
            group.notify(queue: .main) { // Wait for dispatch after async
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
            // Search for critic
        else {
            if searchBar.text! != "" {
                var criticList: [(String, String)] = []
                client.index(withName: "users").search(Query(query: searchBar.text!)) { (content, error) in
                    if error == nil {
                        guard let hits = content!["hits"] as? [[String: AnyObject]] else { fatalError("Hits is not a json") }
                        if hits.count == 0 {
                            self.tableView.isUserInteractionEnabled = false
                            self.criticList = []
                            self.tableView.reloadData()
                            self.tableView.isUserInteractionEnabled = true
                        }
                        var hitsSearched = 0
                        for hit in hits {
                            var hitPublic = true
                            var userBlocked = false
                            var hitBlocked = false
                            var checksDone = 0 {
                                didSet {
                                    if checksDone == 2 {
                                        if hitPublic && !userBlocked && !hitBlocked {
                                            criticList.append((hit["name"] as! String, hit["objectID"] as! String))
                                        }
                                        hitsSearched += 1
                                        if hitsSearched == hits.count {
                                            self.tableView.isUserInteractionEnabled = false
                                            self.criticList = criticList
                                            self.tableView.reloadData()
                                            self.tableView.isUserInteractionEnabled = true
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
            else {
                self.tableView.isUserInteractionEnabled = false
                self.criticList = []
                self.tableView.reloadData()
                self.tableView.isUserInteractionEnabled = true
            }
        }
    }
    
    func getCritics() {
        var critics: [String: Critic] = [:]
        var usersBlocked: [String]! = []
        var usersFollowing: [String]! = []
        var usersFollowers: [String] = []
        let userID = Auth.auth().currentUser!.uid
        db.collection("users").getDocuments { (snapshot, error) in
            if error == nil {
                for document in snapshot!.documents {
                    let criticID = document.documentID
                    let data = document.data()
                    if data["isPublic"] as! Bool && !(data["blocked"] as! [String]).contains(userID) && criticID != userID {
                        critics[criticID] = Critic(name: data["name"] as! String, following: data["following"] as! [String])
                    }
                    else if criticID == userID {
                        usersFollowing = (data["following"] as! [String])
                        usersBlocked = (data["blocked"] as! [String])
                        usersBlocked.append(userID)
                    }
                }
                for blockedCritic in usersBlocked {
                    critics[blockedCritic] = nil
                }
                for (uid, follower) in critics {
                    for followedID in follower.following {
                        if let followed = critics[followedID] {
                            followed.followers.append(uid)
                        }
                        else if followedID == userID {
                            usersFollowers.append(uid)
                        }
                    }
                }
                for followedByUserID in usersFollowing {
                    if let followedByFollowedList = critics[followedByUserID]?.following {
                        for followedByFollowedID in followedByFollowedList {
                            critics[followedByFollowedID]?.weight += 10
                        }
                    }
                    if let followerOfFollowedList = critics[followedByUserID]?.followers {
                        for followerOfFollowedID in followerOfFollowedList {
                            critics[followerOfFollowedID]?.weight += 4
                            for followedByfollowerOfFollowedID in critics[followerOfFollowedID]?.following ?? [] {
                                critics[followedByfollowerOfFollowedID]?.weight += 2
                            }
                        }
                    }
                }
                for followerOfUserID in usersFollowers {
                    critics[followerOfUserID]?.weight += 3
                    for followedByFollowerID in critics[followerOfUserID]?.following ?? [] {
                        critics[followedByFollowerID]?.weight += 1
                    }
                }
                for followedByUserID in usersFollowing {
                    critics[followedByUserID] = nil
                }
                self.discoveryTableView.isUserInteractionEnabled = false
                self.critics = critics.sorted(by: { $0.value > $1.value })
                self.discoveryTableView.reloadData()
                self.discoveryTableView.refreshControl?.endRefreshing()
                self.discoveryTableView.isUserInteractionEnabled = true
            }
            else {
                fatalError(error!.localizedDescription)
            }
        }
    }
    
    // Gets search results for a movie query using the OMDB API
    func getMovieList(movieQuery: String, page: Int = 1) {
        var unallowedUrlString = "http://www.omdbapi.com/?s=" + movieQuery + "&apikey=" + self.omdbApiKey
        unallowedUrlString += "&page=" + String(page)
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
                                    self.movieList += titleList
                                }
                                if let movieDict = movieNSDict as? [String: Any] {
                                    let results: Int = Int(movieDict["totalResults"] as? String ?? String()) ?? 0
                                    if results > page * 10 && page <= 4 {
                                        self.getMovieList(movieQuery: movieQuery, page: page + 1)
                                    }
                                    else {
                                        self.group.leave()
                                    }
                                }
                                else {
                                    self.group.leave()  // async done, i.e. sema down
                                }
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
