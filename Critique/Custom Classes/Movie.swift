//
//  Movie.swift
//  Critique
//
//  Created by Tony Gonelli on 7/4/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import Foundation
import UIKit

class Movie {
    
    var imdbID: String! // A unique identifier for a movie on IMDB
    var title: String = "(blank movie title)"
    var movieData: Dictionary<String, Any>!
    var poster: UIImage = UIImage(named: "missing")!
    var outsideGroup: DispatchGroup
    var outsideGroupEntered: Bool
    let group = DispatchGroup()
    var movieCell: SearchMovieImageCell? = nil
    var omdbApiKey = "nokey"
//    let posterGroup = DispatchGroup()
    
    // Initialize object using the IMDB ID
    init (imdbId: String, outsideGroup: DispatchGroup = DispatchGroup(), outsideGroupEntered: Bool = false) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let keys = appDelegate.keys
        omdbApiKey = keys?["omdbApiKey"] as? String ?? "nokey"
        
        self.outsideGroupEntered = outsideGroupEntered
        self.outsideGroup = outsideGroup
        self.imdbID = imdbId
        self.group.enter()
        
        DispatchQueue.main.async {
            self.getMovieDict(imdbId: imdbId)
        }
        self.group.notify(queue: .main) {
//            self.posterGroup.enter()
            self.getMoviePoster(photoString: (self.movieData["Poster"] as? String)!)
        }
    }
    
    // Load poster given a URL
    func getMoviePoster(photoString: String) {
        // SOURCE: (thank you Andy Ibanez) https://stackoverflow.com/questions/39813497/swift-3-display-image-from-url/39813761
        
        let pictureURL = URL(string: photoString)!
        
        // Creating a session object with the default configuration.
        // You can read more about it here https://developer.apple.com/reference/foundation/urlsessionconfiguration
        let session = URLSession(configuration: .default)
        
        
        // Define a download task. The download task will download the contents of the URL as a Data object and then you can do what you wish with that data.
        let downloadPicTask = session.dataTask(with: pictureURL) { (data, response, error) in
            // The download has finished.
            if let e = error {
                print("Error downloading picture: \(e)")
            }
            else {
                // No errors found.
                // It would be weird if we didn't have a response, so check for that too.
                if (response as? HTTPURLResponse) != nil {
                    if let imageData = data {
                        // Finally convert that Data into an image and do what you wish with it.
                        if let image = UIImage(data: imageData) {
                            self.poster = image
                            if self.movieCell != nil {
                                DispatchQueue.main.async {
                                    self.movieCell?.posterThumbnail.image = image
                                }
                            }
                            if self.outsideGroupEntered { self.outsideGroup.leave()
                                self.outsideGroupEntered = false
                                
                            }
                        }
                    }
                    else {
                        print("Couldn't get image: Image is nil")
                    }
                }
                else {
                    print("Couldn't get response code for some reason")
                }
            }
        }
        downloadPicTask.resume()
    }
    
    // Fetch a movie's info in JSON format given an IMDB ID
    func getMovieDict(imdbId: String) {
        if let url = URL(string: "http://www.omdbapi.com/?i=" + imdbId + "&apikey=" + omdbApiKey) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    if String(data: data, encoding: .utf8) != nil {
                        do {
                            let movieDict : NSDictionary = try JSONSerialization.jsonObject(with: data, options: []) as! NSDictionary
                            DispatchQueue.main.async {
                                self.movieData = movieDict as? Dictionary<String, Any>
                                self.group.leave()
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
