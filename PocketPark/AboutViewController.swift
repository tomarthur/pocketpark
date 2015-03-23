//
//  AboutViewController.swift
//  
//
//  Created by Tom Arthur on 2/23/15.
//
//

import UIKit

class AboutViewController: UIViewController {
    
    @IBOutlet weak var titleText: UILabel!
    @IBOutlet weak var documenationButton: UIButton!
    @IBOutlet weak var acknoledgementsBUtton: UIButton!
    @IBOutlet weak var createOwnButton: UIButton!
    
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleText.font = UIFont(name:"OtterFont", size: 35)
        titleText.adjustsFontSizeToFitWidth = true
        self.view.backgroundColor = .ITWelcomeColor()
    }

    @IBAction func documenationButtonPressed(sender: AnyObject) {
        let alertController = UIAlertController(
        title: "Open Link in Safari?",
        message: "Do you want to view documentation in Safari?",
        preferredStyle: .Alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let openAction = UIAlertAction(title: "Open Safari", style: .Default) { (action) in
            if let url = NSURL(string: "http://tomarthur.github.io/pocketpark") {
                UIApplication.sharedApplication().openURL(url)
            }
        }
        alertController.addAction(openAction)
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    
    @IBAction func acknoledgementsButtonPressed(sender: AnyObject) {
        let alertController = UIAlertController(
            title: "Open Link in Safari?",
            message: "Do you want to view acknoledgements in Safari?",
            preferredStyle: .Alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let openAction = UIAlertAction(title: "Open Safari", style: .Default) { (action) in
            if let url = NSURL(string: "http://tomarthur.github.io/pocketpark/#theme-park-of-everyday-acknowledgements-and-license") {
                UIApplication.sharedApplication().openURL(url)
            }
        }
        alertController.addAction(openAction)
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    @IBAction func createOwnButtonPressed(sender: AnyObject) {
        let alertController = UIAlertController(
            title: "Open Link in Safari?",
            message: "Do you want to view how to create an interactive in Safari?",
            preferredStyle: .Alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let openAction = UIAlertAction(title: "Open Safari", style: .Default) { (action) in
            if let url = NSURL(string: "http://tomarthur.github.io/pocketpark/#theme-park-of-everyday-getting-started") {
                UIApplication.sharedApplication().openURL(url)
            }
        }
        alertController.addAction(openAction)
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    
}
