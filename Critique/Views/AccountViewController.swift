//
//  AccountViewController.swift
//  Critique
//
//  Created by Tony Gonelli on 7/2/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import UIKit
import Foundation

class AccountViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var topBarOuterView: UIView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var followersButtonOutlet: UIButton!
    @IBOutlet weak var followingButtonOutlet: UIButton!
    
    var db: Firestore!
    var accountName = ""
    var accountID = ""
    var tappedPosterTitle = ""
    var tappedPosterMovieObject : Movie? = nil
    var num_following = 0
    var num_followers = 0
    var reviews: [Review] = []
    let followersSegue = "followersSegue"
    let followingSegue = "followingSegue"
    let accountDM_Segue = "accountDM_Segue"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        addRefreshView()
        initializeFirestore()
    }
    
    // Fill in details of page based on whose Profile it is
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Looking at own profile
        if Auth.auth().currentUser != nil {
            if accountName == "" || accountID == "" || accountID == Auth.auth().currentUser!.uid {
                accountID = Auth.auth().currentUser!.uid
                self.getReviews()
                self.getFollowNumbers()
                db.collection("users").document(accountID).getDocument() { (document, error) in
                    if error == nil {
                        self.accountName = document!.data()!["name"] as! String
                        self.navigationItem.title = self.accountName
                    }
                    else {
                        fatalError(error!.localizedDescription)
                    }
                }
            }
            // Looking at another critic's profile
            else {
                getReviews()
                getFollowNumbers()
                self.navigationItem.title = self.accountName
                db.collection("users").document(accountID).getDocument() { (document, error) in
                    if error == nil {
                        let blocked = document!.data()!["blocked"] as! [String]
                        if !blocked.contains(Auth.auth().currentUser!.uid) {
                            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "•••", style: .done, target: self, action: #selector(self.accountAction))
                        }
                        else {
                            self.navigationItem.rightBarButtonItem = nil
                        }
                    }
                    else {
                        fatalError(error!.localizedDescription)
                    }
                }
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    @objc func refresh() {
        print("--refesh--")
        getReviews()
        getFollowNumbers()
    }
    
    func addRefreshView() {
        let refresh = UIRefreshControl()
        tableView.refreshControl = refresh
        refresh.addTarget(self, action: #selector(self.refresh), for: .valueChanged)
    }
    
    func initializeFirestore() {
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        db = Firestore.firestore()
    }
    
    // Fetches reviews by this Profile's critic
    func getReviews() {
        var reviews: [Review] = []
        db.collection("reviews").whereField("criticID", isEqualTo: self.accountID).getDocuments(completion: { (snapshot, _) in
            //TODO: custom MovieInfoCell, not FeedTableViewCell
            for review in snapshot!.documents {
                let body = review.data()["body"] as! String
                let score = review.data()["score"] as! NSNumber
                let criticID = review.data()["criticID"] as! String
                let likers = review.data()["liked"] as! [String]
                let dislikers = review.data()["disliked"] as! [String]
                let imdbID = review.data()["imdbID"] as! String
                let timestamp = review.data()["timestamp"] as! TimeInterval
                reviews.append(Review(imdbID: imdbID, criticID: criticID, likers: likers, dislikers: dislikers, body: body, score: score, timestamp: timestamp, timeSort: true))
            }
            self.tableView.isUserInteractionEnabled = false
            self.reviews = reviews.sorted()
            self.tableView.reloadData()
            self.tableView.refreshControl?.endRefreshing()
            self.tableView.isUserInteractionEnabled = true
        })
    }
    
    // Calculates the number of critics the user is following and followed by
    func getFollowNumbers() {
        // Number of Following
        db.collection("users").document(accountID).getDocument { (document, error) in
            if error == nil {
                let followingList = document!.data()!["following"] as! [String]
                self.num_following = followingList.count
            }
            self.followingButtonOutlet.setTitle("\(self.num_following) Following",for: .normal)
        }
        
        // Number of Followers
        self.num_followers = 0
        db.collection("users").getDocuments{ (snapshot, _) in
            for critic in snapshot!.documents {
                for following in critic.data()["following"] as! [String] {
                    if following == self.accountID {
                        self.num_followers += 1
                    }
                }
            }
            self.followersButtonOutlet.setTitle("\(self.num_followers) Followers",for: .normal)
        }
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.reviews.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "accountReviewCell", for: indexPath) as! FeedTableViewCell
        cell.review = self.reviews[indexPath.row]
        
        let posterTap = ReviewCellTapGesture(target: self, action: #selector(self.handleTap(_:)))
        posterTap.imdbID = cell.review!.imdbID
        cell.posterImage.addGestureRecognizer(posterTap)
        cell.posterImage.isUserInteractionEnabled = true
        
        cell.selectionStyle = .none
        
        if cell.review!.criticID == Auth.auth().currentUser!.uid {
//            let critiqueRed = UIColor(red:0.88, green:0.17, blue:0.13, alpha:0.7)
//            cell.criticLabel.mixedTextColor = MixedColor(normal: critiqueRed.darker(by: 25)!, night: critiqueRed.lighter(by: 25)!)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Fixes account page bottom cell issue ?????????????????
        let _ = tableView.dequeueReusableCell(withIdentifier: "accountReviewCell", for: indexPath) as! FeedTableViewCell
    }
    
    // If movie poster is pressed, show the movie's info
    @objc func handleTap(_ sender: ReviewCellTapGesture? = nil) {
        // Poster tapped
        let feedGroup = DispatchGroup()
        feedGroup.enter()
        var outgoingMovie = Movie(imdbId: "tt0848228")
        
        DispatchQueue.main.async {
            outgoingMovie = Movie(imdbId: sender!.imdbID, outsideGroup: feedGroup, outsideGroupEntered: true)
        }
        feedGroup.notify(queue: .main) {
            self.tappedPosterTitle = outgoingMovie.movieData["Title"] as! String
            self.tappedPosterMovieObject = outgoingMovie
            self.performSegue(withIdentifier: "accountPosterSegue", sender: self)
        }
    }
    
    // accountPosterSegue
    // Segue to Following/Followers/Expanded screens
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == followersSegue {
            let nextVC = segue.destination as! FollowsTableViewController
            nextVC.lookupType = "Followers"
            nextVC.user = accountID
        }
        else if segue.identifier == followingSegue {
            let nextVC = segue.destination as! FollowsTableViewController
            nextVC.lookupType = "Following"
            nextVC.user = accountID
        }
        else if segue.identifier == "accountMovieExpandSegue", let nextVC = segue.destination as? ExpandedReviewTableViewController , let reviewIndex = tableView.indexPathForSelectedRow?.row {
            nextVC.deligate = self
            nextVC.expanedReview = reviews[reviewIndex]
        }
        else if segue.identifier == accountDM_Segue, let nextVC = segue.destination as? ChatViewController {
            nextVC.chat = Chat(sender as! String)
            nextVC.messageInputBar.becomeFirstResponder()
            nextVC.incomingName = accountName
        }
        else if segue.identifier == "accountPosterSegue" {
            let infoVC = segue.destination as! MovieInfoViewController
            infoVC.movieTitle = self.tappedPosterTitle
            infoVC.movieObject = self.tappedPosterMovieObject
        }
    }
    
    // Generate action screen for when user clicks on options button
    @objc func accountAction() {
        let controller = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet)
        
        let blockAction = UIAlertAction(
            title: "Block",
            style: .destructive,
            handler:  {(alert) in
                let ref = self.db.collection("users").document(Auth.auth().currentUser!.uid)
                ref.getDocument { (document, error) in
                    if error == nil {
                        // When blocked button pressed
                        var blocked = document!.data()!["blocked"] as! [String]
                        blocked.append(self.accountID)
                        var following = document!.data()!["following"] as! [String]
                        following.removeAll { $0 == self.accountID }
                        ref.setData(["blocked": blocked], merge: true)
                        ref.setData(["following": following], merge: true)
                        let refBlocked = self.db.collection("users").document(self.accountID)
                        refBlocked.getDocument() { (document, error) in
                            following = document!.data()!["following"] as! [String]
                            following.removeAll { $0 == Auth.auth().currentUser!.uid }
                            refBlocked.setData(["following": following], merge: true)
                        }
                        
                        // Remove any messaging history
                        let chatGroup = [self.accountID, Auth.auth().currentUser!.uid]
                        self.chatExists(userList: chatGroup) { chatID in
                            for user in chatGroup {
                                var userChats:[String] = []
                                self.db.collection("users").document(user).getDocument(){ (document, error) in
                                    if error == nil, let chatDoc = document {
                                        userChats = chatDoc.data()!["myChats"] as! [String]
                                        if let index = userChats.firstIndex(of: chatID) {
                                            userChats.remove(at: index)
                                            self.db.collection("users").document(user).setData(["myChats": userChats], merge: true)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    else {
                        fatalError(error!.localizedDescription)
                    }
                }
        }
        )
        
        let unblockAction = UIAlertAction(
            title: "Unblock",
            style: .destructive,
            handler:  {(alert) in
                let ref = self.db.collection("users").document("\(Auth.auth().currentUser!.uid)")
                ref.getDocument { (document, error) in
                    if error == nil {
                        // When unblock pressed
                        var blocked = document!.data()!["blocked"] as! [String]
                        blocked.removeAll { $0 == self.accountID }
                        ref.setData(["blocked": blocked], merge: true)
                    }
                    else {
                        fatalError(error!.localizedDescription)
                    }
                }
        }
        )
        
        let messageAction = UIAlertAction(
            title: "Message",
            style: .default,
            handler: {(alert) in
                var targetChatID = ""
                let chatGroup = [Auth.auth().currentUser!.uid, self.accountID]
                // Check to see if there exists a chat between these two users and ONLY these two users
                self.chatRequest(chatGroup) { (approved, chatID) in
                    if approved {
                        self.db.collection("users").document(Auth.auth().currentUser!.uid).getDocument() { (document, error) in
                            if error == nil, let chatDoc = document {
                                var userChats = chatDoc.data()!["myChats"] as! [String]
                                if !userChats.contains(chatID!) {
                                    userChats.append(chatID!)
                                    self.db.collection("users").document(Auth.auth().currentUser!.uid).setData(["myChats": userChats], merge: true)
                                }
                            }
                        }
                        targetChatID = chatID!
                    } else if chatID != nil {
                        targetChatID = chatID!
                        print("\n\nTARGET CHAT ID:\(targetChatID)\n\n")
                    } else {
                        //break
                        print("\n\nERROR HANDLING NOT IMPLEMENTED YET\n\n")
                    }
                    //Navigate to chat
                    if targetChatID != "" {
                        self.performSegue(withIdentifier: self.accountDM_Segue, sender: targetChatID)
                    }
                }
        }
        )
        
        let ref = self.db.collection("users").document("\(Auth.auth().currentUser!.uid)")
        
        let followAction = UIAlertAction(
            title: "Follow",
            style: .default,
            handler: {(alert) in
                ref.getDocument { (document, error) in
                    if error == nil {
                        // When follow pressed
                        var following = document!.data()!["following"] as! [String]
                        following.append(self.accountID)
                        ref.setData(["following": following], merge: true)
                        self.getFollowNumbers()
                    }
                    else {
                        fatalError(error!.localizedDescription)
                    }
                }
        }
        )
        
        let unfollowAction = UIAlertAction(
            title: "Unfollow",
            style: .default,
            handler: {(alert) in
                ref.getDocument { (document, error) in
                    if error == nil {
                        // When unfollow pressed
                        var following = document!.data()!["following"] as! [String]
                        following.removeAll { $0 == self.accountID }
                        ref.setData(["following": following], merge: true)
                        self.getFollowNumbers()
                    }
                    else {
                        fatalError(error!.localizedDescription)
                    }
                }
        }
        )
        
        let cancelAction = UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: { (action) in print("Cancel Action")}
        )
        
        messageAction.setValue(UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0), forKey: "titleTextColor")
        unfollowAction.setValue(UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0), forKey: "titleTextColor")
        followAction.setValue(UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0), forKey: "titleTextColor")
        cancelAction.setValue(UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0), forKey: "titleTextColor")
        
        // Selectively include options based on if they are blocked or followed
        ref.getDocument { (document, error) in
            if error == nil {
                let following = document!.data()!["following"] as! [String]
                let blocked = document!.data()!["blocked"] as! [String]
                if following.contains(self.accountID) {
                    controller.addAction(unfollowAction)
                    controller.addAction(messageAction)
                }
                else if !blocked.contains(self.accountID) {
                    controller.addAction(followAction)
                    controller.addAction(messageAction)
                }
                if blocked.contains(self.accountID) {
                    controller.addAction(unblockAction)
                }
                else {
                    controller.addAction(blockAction)
                }
                controller.addAction(cancelAction)
                self.present(controller, animated: true, completion: nil)
            }
            else {
                fatalError(error!.localizedDescription)
            }
        }
    }
    
    func chatRequest(_ users:[String] ,completion: @escaping (Bool, String?) -> Void) {
        
        db.collection("chats").getDocuments() { (snapshot, error) in
            var createNew = true
            if error == nil, let snapshot = snapshot {
                var syncCount = -1*(snapshot.documents.count)
                if syncCount == 0 && createNew {
                    var data: [String: Any] = ["messages": [], "users": users]
                    for user in users {
                        data[user] = []
                    }
                    let chatDoc = self.db.collection("chats").addDocument(data: data)
                    completion(true, chatDoc.documentID)
                }
                for chatDoc in snapshot.documents {
                    let chat = chatDoc.documentID
                    self.chatExists(userList: users, chatID: chat){ (exists) in
                        syncCount += 1
                        if exists {
                            createNew = false
                            completion(true, chat)
                            print("Sync Count: \(syncCount) | Create New: \(createNew)")
                        } else if syncCount == 0 && createNew {
                            var data: [String: Any] = ["messages": [], "users": users]
                            for user in users {
                                data[user] = []
                            }
                            let chatDoc = self.db.collection("chats").addDocument(data: data)
                            completion(true, chatDoc.documentID)
                        }
                    }
                }
            } else {
                completion(false, nil)
            }
        }
        
        //        db.collection("users").document(Auth.auth().currentUser!.uid).getDocument(){ (document, error) in
        //            var createNew = true
        //            if error == nil, let userDoc = document {
        //                var syncCount = -1*(userDoc.data()?["myChats"] as! [String]).count
        //                for chat in userDoc.data()?["myChats"] as! [String] {
        //                    self.chatExists(userList: users, chatID: chat){ (exists) in
        //                        syncCount += 1
        //                        if exists {
        //                            createNew = false
        //                            completion(false, chat)
        //                            print("Sync Count: \(syncCount) | Create New: \(createNew)")
        //                        } else if syncCount == 0 && createNew {
        //                            let chatDoc = self.db.collection("chats").addDocument(data:
        //                                ["messages": [],
        //                                 "users": users
        //                                ])
        //                            completion(true, chatDoc.documentID)
        //                        }
        //                    }
        //                }
        //            } else {
        //                completion(false, nil)
        //            }
        //        }
    }
    
    func chatExists(userList users:[String], completion: @escaping (String) -> Void) {
        
        db.collection("chats").getDocuments() { (snapshot, error) in
            var found = false
            
            if error == nil, let snapshot = snapshot {
                for chatDoc in snapshot.documents {
                    let chat = chatDoc.documentID
                    self.chatExists(userList: users, chatID: chat){ (exists) in
                        if exists {
                            completion(chat)
                            found = true
                        }
                    }
                    
                    if found {
                        break
                    }
                }
            }
        }
    }
    
    func chatExists(userList users:[String], chatID chat:String, completion: @escaping (Bool) -> Void) {
        self.db.collection("chats").document(chat).getDocument(){ (document, error) in
            if error == nil, let chatDoc = document {
                let existingChat = chatDoc.data()!["users"] as! [String]
                if users.sorted() == existingChat.sorted() {
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }
    
}
