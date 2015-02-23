//
//  SettingsViewController.swift
//  
//
//  Created by Tom Arthur on 2/23/15.
//
//

import UIKit

class SettingsViewController: UIViewController {
    
    var swipeRecognizer: UISwipeGestureRecognizer!
    
    func handleSwipes(sender: UISwipeGestureRecognizer){
        if sender.direction == .Right{
            self.dismissViewControllerAnimated(true, completion:nil)
        }
    }
    
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

    override func viewDidLoad() {
        println("Howdy from Settings View")
        super.viewDidLoad()
        
        swipeRecognizer = UISwipeGestureRecognizer(target: self, action: "handleSwipes:")
        self.view.addGestureRecognizer(swipeRecognizer)
        /* Swipes that are perfomed from the right to the left are to be detected to end connection to interactive */
        swipeRecognizer.direction = .Right
        swipeRecognizer.numberOfTouchesRequired = 1
    }
    
}
