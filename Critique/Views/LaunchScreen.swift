//
//  LaunchScreen.swift
//  Critique
//
//  Created by Tony Gonelli on 7/27/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore
import FirebaseAuth

class LaunchScreen: UIViewController, CAAnimationDelegate {
    
    var tapCount = 0
    
    @IBOutlet var NameHider: UIImageView!
    @IBOutlet var myButton: UIButton!
    @IBOutlet var CritiqueName: UIImageView!
    @IBOutlet var Popcorn: UIImageView!
    @IBOutlet var CqInitials: UIImageView!
    
    override func viewDidLoad() {

    }
    @IBAction func myButtonPressed(_ sender: Any) {
        self.spin1()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        usleep(100000) // 0.1 sec.
        self.spin1()
        self.moveName()
        self.movePopcorn()
    }
    
    func spin1() {
        UIView.animate(withDuration: 0.4, animations: {
            self.Popcorn.transform = CGAffineTransform(rotationAngle:  CGFloat.pi / -8)
            self.Popcorn.transform = CGAffineTransform(rotationAngle:  CGFloat.pi / -3)
            self.view.layoutIfNeeded()
        },
        completion: { finished in
            self.spin2()
        })
        
    }
    
    func spin2() {
        UIView.animate(
            withDuration: 0.3,
            animations: {
                self.Popcorn.transform =
                    self.Popcorn.transform.rotated(by: CGFloat(Double.pi / 3))
                self.view.layoutIfNeeded()
        },
            completion:{ finished in
                self.zoomPopcorn()
        }
        )
    }
    
    func moveName() {
        UIView.animate(
            withDuration: 0.6,
            animations: {
                self.CritiqueName.center.x -= self.view.center.x / 2
        },
            completion:{ finished in
                self.NameHider.isHidden = true
                self.CritiqueName.isHidden = true
        }
        )
    }
    
    func movePopcorn() {
        let distanceToMove = self.view.center.x - self.Popcorn.center.x
        
        UIView.animate(
            withDuration: 0.6,
            animations: {
                self.Popcorn.center.x += distanceToMove
        }
        )
        
        UIView.animate(
            withDuration: 0.6,
            animations: {
                self.CqInitials.center.x += distanceToMove
        }
        )
        
        UIView.animate(
            withDuration: 0.7,
            animations: {
                self.NameHider.center.x += distanceToMove
        }
        )
    }
    
    func zoomPopcorn() {
        UIView.animate(
            withDuration: 0.10,
            delay: 0.0,
            options: .curveEaseIn,
            animations: {
                self.Popcorn.transform = CGAffineTransform.identity.scaledBy(x: 0.8, y: 0.8) // Scale your image
            }) { finished in
                UIView.animate(withDuration: 0.10, animations: {
                self.Popcorn.transform = CGAffineTransform.identity
            })
        }
        
        UIView.animate(
            withDuration: 0.10,
            delay: 0.0,
            options: .curveEaseIn,
            animations: {
                self.CqInitials.transform = CGAffineTransform.identity.scaledBy(x: 0.8, y: 0.8) // Scale your image
        }) { finished in
                UIView.animate(withDuration: 0.10, animations: {
                self.CqInitials.transform = CGAffineTransform.identity
                }, completion: {finished in
                    if (Auth.auth().currentUser == nil) {
                        self.performSegue(withIdentifier: "BootupLoginSegue", sender: self)
                    }
                    else {
                        self.performSegue(withIdentifier: "BootupFeedSegue", sender: self)
                        
                    }})
            }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.Popcorn.isHidden = true
        self.CqInitials.isHidden = true
    }
}
