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
import NightNight

import FirebaseStorage

class SettingsViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var libraryButton: UIBarButtonItem!
    @IBOutlet var NameChangeCell: UITableViewCell!
    @IBOutlet var BlockedCell: UITableViewCell!
    @IBOutlet var PublicCell: UITableViewCell!
    @IBOutlet var nightModeCell: UITableViewCell!
    @IBOutlet weak var publicSwitch: UISwitch!
    @IBOutlet var nightModeSwitch: UISwitch!
    @IBOutlet var publicLabel: UILabel!
    @IBOutlet var nightModeLabel: UILabel!
    @IBOutlet var signOutCell: UITableViewCell!
    
    var db: Firestore!
    let client = Client(appID: "3PCPRD2BHV", apiKey: "e2ab8935cad696d6a4536600d531097b")
    let picker = UIImagePickerController()
    let critiqueRed = 0xe12b22
    let nightBgColor = 0x222222
    let nightTextColor = 0xdddddd
    let mixedNightBgColor = MixedColor(normal: 0xffffff, night: 0x222222)
    let mixedNightTextColor = MixedColor(normal: 0x000000, night: 0xdddddd)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Settings"
        picker.delegate = self
        
        BlockedCell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        NameChangeCell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        
        initializeFirestore()
        
        // Set switch based on account privacy
        let doc = self.db.collection("users").document("\(Auth.auth().currentUser!.uid)")
        doc.getDocument { (document, error) in
            let val = document!.data()!["isPublic"]! as! Bool
            if !val {
                self.publicSwitch.setOn(false, animated: false)
            }
        }
        
        // NightNight
        self.navigationController!.navigationBar.mixedBarTintColor = MixedColor(normal: UIColor(red: 0.969, green: 0.969, blue: 0.969, alpha: 1.0), night: UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0))
        self.navigationController!.navigationBar.mixedBarStyle = MixedBarStyle(normal: .default, night: .black)
        if(NightNight.theme == .night) { // Idk but it works to fix statusbar color
            NightNight.theme = .night
        }
        else {
            NightNight.theme = .normal
        }
        tableView.mixedBackgroundColor = MixedColor(normal: 0xefeff4, night: 0x161616)
        
        NameChangeCell.textLabel?.mixedTextColor = mixedNightTextColor
        NameChangeCell.mixedBackgroundColor = mixedNightBgColor
        NameChangeCell.selectionStyle = .none
        
        BlockedCell.textLabel?.mixedTextColor = mixedNightTextColor
        BlockedCell.mixedBackgroundColor = mixedNightBgColor
        BlockedCell.selectionStyle = .none
        
        publicLabel.mixedTextColor = mixedNightTextColor
        PublicCell.mixedBackgroundColor = mixedNightBgColor
        PublicCell.selectionStyle = .none
        
        nightModeLabel.mixedTextColor = mixedNightTextColor
        nightModeCell.mixedBackgroundColor = mixedNightBgColor
        nightModeCell.selectionStyle = .none
        
        signOutCell.textLabel?.mixedTextColor = MixedColor(normal: critiqueRed, night: nightTextColor)
        signOutCell.mixedBackgroundColor = mixedNightBgColor
        
        
        if NightNight.theme == .night {
            self.nightModeSwitch.setOn(true, animated: false)
            self.navigationController!.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(red:0.87, green:0.87, blue:0.87, alpha:1.0)]
            
        }
        else {
            self.nightModeSwitch.setOn(false, animated: false)
            self.navigationController!.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        }
    }
    
    func initializeFirestore() {
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        db = Firestore.firestore()
    }
    
    @IBAction func libraryButtonPressed(_ sender: Any) {
        // whole picture, not going to allow editing before returning
        picker.allowsEditing = false
        
        // set the source to be the Photo Library
        picker.sourceType = .photoLibrary
        
        picker.modalPresentationStyle = .popover
        present(picker,animated:true,completion:nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // get the selected picture
        var chosenImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        
        self.uploadProfilePhoto(chosenImage: chosenImage)
        
        dismiss(animated:true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated:true,completion:nil)
    }
    
    func uploadProfilePhoto(chosenImage: UIImage) {
        // Data in memory
        let data = chosenImage.pngData()!
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        // Create a reference to the file you want to upload
        let riversRef = storageRef.child("images/\(Auth.auth().currentUser!.uid).jpg")
        
        // Upload the file to the path "images/rivers.jpg"
        let uploadTask = riversRef.putData(data, metadata: nil) { (metadata, error) in
            guard let metadata = metadata else {
                // Uh-oh, an error occurred!
                return
            }
            // Metadata contains file metadata such as size, content-type.
            let size = metadata.size
            // You can also access to download URL after upload.
            riversRef.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    // Uh-oh, an error occurred!
                    return
                }
            }
        }
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
            
            ((self.parent?.parent as! UITabBarController).selectedViewController as! UINavigationController).dismiss(animated: false, completion: nil)
            
            
//
//            if let expanded = (self.parent?.parent as! UITabBarController).selectedViewController as? ExpandedReviewTableViewController {
//                print("EXPANED!")
//                expanded.dismiss(animated: false, completion: nil)
//            }
            (((self.parent?.parent as! UITabBarController).viewControllers![2] as! UINavigationController).children[0] as! AccountViewController).accountID = ""
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @IBAction func publicSwitchPressed(_ sender: Any) {
        changeAccountPrivacy()
    }
    
    @IBAction func nightModeToggled(_ sender: Any) {
        NightNight.toggleNightTheme()
        if (NightNight.theme == .night) {
            self.navigationController!.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(red:0.87, green:0.87, blue:0.87, alpha:1.0)]
        }
        else {
            self.navigationController!.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        }
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
