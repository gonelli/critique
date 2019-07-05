//
//  AccountViewController.swift
//  Critique
//
//  Created by Tony Gonelli on 7/2/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit
import Foundation

class AccountViewController: UIViewController {
    
    @IBOutlet var accountTabLabel: UILabel!

    @IBOutlet var accountTextView: UITextView!
    @IBOutlet var accountButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Account"
    }
    
    func getMovieDict(imdbId: String, apiKey: String) {
        if let url = URL(string: "http://www.omdbapi.com/?s=" + imdbId + "&apikey=" + apiKey) {
            
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    if String(data: data, encoding: .utf8) != nil {
                        do {
                            let movieNSDict : NSDictionary = try JSONSerialization.jsonObject(with: data, options: []) as! NSDictionary
                            DispatchQueue.main.async {
                                if let movieDict = movieNSDict as? [String: Any] {
                                    let search: Array<Dictionary<String, String>> = movieDict["Search"] as! Array<Dictionary<String, String>>
                                    let index: Dictionary<String, String> = search[0]
                                    let title = index["Title"]
                                    self.accountTextView.text = title

                                }
                                
                                print(movieNSDict)
//                                self.accountTextView.text = movieNSDict["Title"] as! String
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
    
    @IBAction func accountButtonPressed(_ sender: Any) {
        self.getMovieDict(imdbId: "Avengers", apiKey: "7cc21a66")
    }

}
