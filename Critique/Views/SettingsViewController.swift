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
import InstantSearchClient

class SettingsViewController: UITableViewController {
    
    @IBOutlet var NameChangeCell: UITableViewCell!
    @IBOutlet var BlockedCell: UITableViewCell!
    @IBOutlet var PublicCell: UITableViewCell!
    @IBOutlet weak var publicSwitch: UISwitch!
    
    var db: Firestore!
    let client = Client(appID: "3PCPRD2BHV", apiKey: "e2ab8935cad696d6a4536600d531097b")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Settings"
        
        BlockedCell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        NameChangeCell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        
        initializeFirestore()
        
        // Set switch based on account privacy
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
    
    // Take action depending on what setting the user pressed
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      // Change Name
      if (indexPath.section == 0 && indexPath.row == 0) {
        let controller = UIAlertController(
          title: "Change Name",
          message: "Please enter a new name.",
          preferredStyle: .alert)
        
        controller.addTextField(configurationHandler: {
            (textField:UITextField!) in textField.placeholder = "New Name"
        })
        let confirmAction = UIAlertAction(
            title: "Confirm",
            style: .default,
            handler: { (paramAction:UIAlertAction!) in
                if let textFields = controller.textFields {
                    let theTextFields = textFields as [UITextField]
                    let enteredText = theTextFields[0].text!
                    self.db.collection("users").document("\(Auth.auth().currentUser!.uid)").setData([ "name": enteredText ], merge: true)
                    self.client.index(withName: "users").partialUpdateObject(["name": enteredText], withID: "\(Auth.auth().currentUser!.uid)")
                }
            }
        )
        controller.addAction(confirmAction)
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        controller.preferredAction = confirmAction
        present(controller,animated:true,completion:nil)
      }
      // Blocked
      else if (indexPath.section == 0 && indexPath.row == 1) {
        performSegue(withIdentifier: "blockedSegue", sender: self)
      }
      // Account Privacy
      else if (indexPath.section == 0 && indexPath.row == 2) {
        changeAccountPrivacy()
      }
      // Sign Out
      else if (indexPath.section == 1 && indexPath.row == 0) {
        try! Auth.auth().signOut()
        (self.parent?.parent as! UITabBarController).selectedIndex = 0
        (((self.parent?.parent as! UITabBarController).viewControllers![2] as! UINavigationController).children[0] as! AccountViewController).accountID = ""
      }
      tableView.deselectRow(at: indexPath, animated: true)
    }
  
    @IBAction func publicSwitchPressed(_ sender: Any) {
        changeAccountPrivacy()
    }
    
    // Store and flip switch
    func changeAccountPrivacy() {
        let doc = self.db.collection("users").document("\(Auth.auth().currentUser!.uid)")
        doc.getDocument { (document, error) in
            let oldVal = document!.data()!["isPublic"]! as! Bool
            doc.setData(["isPublic": !oldVal], merge: true)
            if !oldVal {
                self.publicSwitch.setOn(true, animated: true)
            }
            else {
                self.publicSwitch.setOn(false, animated: true)
            }
        }
    }
}
