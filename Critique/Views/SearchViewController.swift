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
import NightNight

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var discoveryTableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var movieList:Array<(String, Movie)> = Array<(String, Movie)>() // list of movie results - tuple stores name and Movie object
    var criticList: [(String, String)] = [] // list of critic results - tuple stores name and UID
    var critics: [(String, Critic)] = []
    let group = DispatchGroup()
    
    let client = Client(appID: "3PCPRD2BHV", apiKey: "e2ab8935cad696d6a4536600d531097b") // Algolia client
    let cellIdentifier = "searchResultCell"
    let movieInfoSegue = "movieInfoSegue"
    let criticProfileSegue = "criticProfileSegue"
    let critiqueRed = 0xe12b22
    let nightBgColor = 0x222222
    let nightTextColor = 0xdddddd
    let mixedNightBgColor = MixedColor(normal: 0xffffff, night: 0x222222)
    let mixedNightTextColor = MixedColor(normal: 0x000000, night: 0xdddddd)
    
    var db: Firestore!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Search"
        
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
        initFirestore()
        
        // NIGHT NIGHT
        self.navigationController!.navigationBar.mixedBarTintColor = MixedColor(normal: UIColor(red: 0.969, green: 0.969, blue: 0.969, alpha: 1.0), night: UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0))
        self.navigationController!.navigationBar.mixedBarStyle = MixedBarStyle(normal: .default, night: .black)
        segmentedControl.mixedTintColor = MixedColor(normal: critiqueRed, night: nightTextColor)
        searchBar.mixedBackgroundColor = mixedNightBgColor
        view.mixedBackgroundColor = mixedNightBgColor
        tableView.mixedBackgroundColor = mixedNightBgColor
        discoveryTableView.mixedBackgroundColor = mixedNightBgColor
        searchBar.mixedTintColor = MixedColor(normal: UIColor.red, night: UIColor.red)
        (searchBar.value(forKey: "searchField") as? UITextField)?.mixedTextColor = mixedNightTextColor
        if(NightNight.theme == .night) { // Idk but it works to fix statusbar color
            NightNight.theme = .night
        }
        else {
            NightNight.theme = .normal
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getCritics()
        // NightNight exception
        if (NightNight.theme == .night) {
            self.navigationController!.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(red:0.87, green:0.87, blue:0.87, alpha:1.0)]
            searchBar.keyboardAppearance = .dark
        }
        else {
            self.navigationController!.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
            searchBar.keyboardAppearance = .default
        }
    }
    
    func initFirestore() {
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        db = Firestore.firestore()
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
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath as IndexPath)
            let row = indexPath.row
            
            if segmentedControl.selectedSegmentIndex == 0 {
                cell.textLabel?.text = movieList[row].0
            }
            else {
                cell.textLabel?.text = criticList[row].0
            }
            
            // NightNight
            cell.selectionStyle = .none
            cell.mixedBackgroundColor = mixedNightBgColor
            cell.textLabel?.mixedTextColor = mixedNightTextColor
            
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "discoveryCell", for: indexPath as IndexPath) as! DiscoveryTableViewCell
            let critic = critics[indexPath.row].1
            
            cell.setCell(name: critic.name!, followers: critic.followers.count, following: critic.following.count)
            
            
            // NightNight
            cell.selectionStyle = .none
            cell.mixedBackgroundColor = mixedNightBgColor
            cell.nameLabel?.mixedTextColor = mixedNightTextColor
            
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
            criticList = []
            tableView.reloadData()
        }
        else {
            movieList = Array<(String, Movie)>()
            tableView.reloadData()
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
                            self.criticList = []
                            self.tableView.reloadData()
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
                                            self.criticList = criticList
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
            else {
                self.criticList = []
                self.tableView.reloadData()
            }
        }
    }
    
    func getCritics() {
        var critics: [String: Critic] = [:]
        var usersBlocked: [String]!
        var usersFollowing: [String]!
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
                self.critics = critics.sorted(by: { $0.value > $1.value })
                self.discoveryTableView.reloadData()
            }
            else {
                fatalError(error!.localizedDescription)
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
