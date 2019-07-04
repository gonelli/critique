//
//  SearchViewController.swift
//  Critique
//
//  Created by Tony Gonelli on 7/2/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {
    
    let searchSegueIdentfier = "searchSegue"
    
    @IBOutlet weak var movieSearchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Search"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // use appropriate identifier string or variable
        if segue.identifier == searchSegueIdentfier {
            let resultVC = segue.destination as! MovieSearchResultViewController
            
            resultVC.searchResults = // list of strings from searching movieSearchBar.text
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
    
}
