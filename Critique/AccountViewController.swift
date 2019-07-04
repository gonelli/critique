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
        if let url = URL(string: "http://www.omdbapi.com/?i=" + imdbId + "&apikey=" + apiKey) {
            
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    if String(data: data, encoding: .utf8) != nil {
                        do {
                            let movieDict : NSDictionary = try JSONSerialization.jsonObject(with: data, options: []) as! NSDictionary
                            DispatchQueue.main.async {
                                self.accountTextView.text = movieDict["Plot"] as? String
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
        self.getMovieDict(imdbId: "tt3896198", apiKey: "7cc21a66")
    }

}
