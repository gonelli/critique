//
//  ComposeTableViewController.swift
//  Critique
//
//  Created by James Jackson on 7/6/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

class ComposeTableViewController: UITableViewController {
    
    var db: Firestore!
    var imdbID: String!
    
    @IBOutlet weak var scoreTF: UITextField!
    @IBOutlet weak var reviewTV: UITextView!
    
    override func viewDidLoad() {
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        db = Firestore.firestore()
        
        scoreTF.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(SearchViewController.dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
    }
    
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if (indexPath.section == 0 && indexPath.row == 0) {
            scoreTF.becomeFirstResponder()
        } else if (indexPath.section == 1 && indexPath.row == 0) {
            reviewTV.becomeFirstResponder()
        }
    }
    
    // Create a new review document in database after review is posted
    @IBAction func post(_ sender: Any) {
        let trimmedReview = reviewTV.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if (Double(scoreTF.text!) == nil || trimmedReview == "") {
            let alert = UIAlertController(title: "All Fields Required", message: "Fill in the score and review fields", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
        else if (Double(scoreTF.text!)! > 10  || Double(scoreTF.text!)! < 0) {
            let alert = UIAlertController(title: "Enter a Valid Score", message: "Scores can be any number from 0-10", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
        else if let currentUser = Auth.auth().currentUser {
            db.collection("reviews").document("\(currentUser.uid)_\(imdbID!)").setData([
                "criticID" : currentUser.uid,
                "imdbID" : imdbID as Any,
                "body" : trimmedReview as Any,
                "liked" : [] as [String],
                "disliked" : [] as [String],
                "score" : Double(scoreTF.text!) as Any,
                "timestamp": Date().timeIntervalSince1970 as Any
                ])
                navigationController?.popViewController(animated: true)
        }
    }
}

extension ComposeTableViewController : UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let textFieldText = textField.text,
            let rangeOfTextToReplace = Range(range, in: textFieldText) else {
                return false
        }
        let substringToReplace = textFieldText[rangeOfTextToReplace]
        let count = textFieldText.count - substringToReplace.count + string.count
        return count <= 4
    }
}
