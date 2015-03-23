//
//  AboutViewController.swift
//  
//
//  Created by Tom Arthur on 2/23/15.
//
//

import UIKit

class AboutViewController: UIViewController {
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .ITWelcomeColor()
    }

    
}
