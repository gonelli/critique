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
    var title: String = "(blank movie title)"
    var movieData: Dictionary<String, Any>!
    var poster: UIImage = UIImage()
    let group = DispatchGroup()
    var imdbID: String!
    
    init (imdbId: String) { //tt0848228
      self.imdbID = imdbId
        self.group.enter()
        
        DispatchQueue.main.async {
            self.getMovieDict(imdbId: imdbId)
        }
        self.group.notify(queue: .main) {
            self.getMoviePoster(photoString: (self.movieData["Poster"] as? String)!)
        }
    }
  
  
  
  
    
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
            } else {
                // No errors found.
                // It would be weird if we didn't have a response, so check for that too.
                if (response as? HTTPURLResponse) != nil {
//                    print("Downloaded picture with response code \(res.statusCode)")
                    if let imageData = data {
                      // Finally convert that Data into an image and do what you wish with it.
                      if let image = UIImage(data: imageData) {
                        self.poster = image
//                        print("Got image")
                      }
                    } else {
                        print("Couldn't get image: Image is nil")
                    }
                } else {
                    print("Couldn't get response code for some reason")
                }
            }
        }
        downloadPicTask.resume()
    }
    
    func getMovieDict(imdbId: String) {
        if let url = URL(string: "http://www.omdbapi.com/?i=" + imdbId + "&apikey=" + "7cc21a66") {
            
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    if String(data: data, encoding: .utf8) != nil {
                        do {
                            let movieDict : NSDictionary = try JSONSerialization.jsonObject(with: data, options: []) as! NSDictionary
                            DispatchQueue.main.async {
                                print(movieDict)
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
