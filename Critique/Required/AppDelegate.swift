//
//  AppDelegate.swift
//  Critique
//
//  Created by James Jackson on 6/24/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseFirestore
import NightNight

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    FirebaseApp.configure()
    self.window?.tintColor = UIColor.red
    let db = Firestore.firestore()
    return true
  }
}
