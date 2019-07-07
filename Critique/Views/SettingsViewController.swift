//
//  SettingsViewController.swift
//  Critique
//
//  Created by Tony Gonelli on 7/2/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

class SettingsViewController: UITableViewController {
    
    @IBOutlet var NameChangeCell: UITableViewCell!
    @IBOutlet var BlockedCell: UITableViewCell!
    @IBOutlet var PublicCell: UITableViewCell!
    @IBOutlet weak var publicSwitch: UISwitch!
    
    var db: Firestore!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Settings"
        
        BlockedCell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        NameChangeCell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        
        initializeFirestore()
        
        let doc = self.db.collection("users").document("\(Auth.auth().currentUser!.uid)")
        doc.getDocument { (document, error) in
            let val = document!.data()!["isPublic"]! as! Bool
            if !val {
                self.publicSwitch.setOn(false, animated: true)
            }
        }
    }
    
    func initializeFirestore() {
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        db = Firestore.firestore()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            let controller = UIAlertController(
                title: "Change Name",
                message: "Please enter a new name.",
                preferredStyle: .alert)
            
            controller.addTextField(configurationHandler: {
                (textField:UITextField!) in textField.placeholder = "New Name"
            })
            
            controller.addAction(UIAlertAction(
                title: "Confirm",
                style: .default,
                handler: {
                    (paramAction:UIAlertAction!) in
                    if let textFields = controller.textFields {
                        let theTextFields = textFields as [UITextField]
                        let enteredText = theTextFields[0].text!
                        self.db.collection("users").document("\(Auth.auth().currentUser!.uid)").setData([ "name": enteredText ], merge: true)
                    }
            }
            ))
            
            controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            present(controller,animated:true,completion:nil)
        case 1:
            performSegue(withIdentifier: "blockedSegue", sender: self)
        case 2:
            changeAccountPrivacy()
        default:
            fatalError("Unknown row pressed")
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @IBAction func publicSwitchPressed(_ sender: Any) {
        changeAccountPrivacy()
    }
    
    
    func changeAccountPrivacy() {
        let doc = self.db.collection("users").document("\(Auth.auth().currentUser!.uid)")
        doc.getDocument { (document, error) in
            let oldVal = document!.data()!["isPublic"]! as! Bool
            doc.setData(["isPublic": !oldVal], merge: true)
            if !oldVal {
                self.publicSwitch.setOn(true, animated: true)
            } else {
                self.publicSwitch.setOn(false, animated: true)
            }
        }
    }
}
