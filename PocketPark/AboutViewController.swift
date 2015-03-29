//
//  AboutViewController.swift
//  
//
//  Created by Tom Arthur on 2/23/15.
//
//

import UIKit
import MessageUI

class AboutViewController: UIViewController, UINavigationBarDelegate {
    
    @IBOutlet weak var explanationText: UILabel!
    @IBOutlet weak var createOwnButton: UIButton!
    @IBOutlet weak var feedbackButton: UIButton!
    @IBOutlet weak var acknowledgementsButton: UIButton!
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        explanationText.textAlignment = .Center;
        makeNavigationBar()
        self.view.backgroundColor = .ITWelcomeColor()
    }
    
    override func viewWillAppear(animated: Bool) {
        makeNavigationBar()
    }
    
    func makeNavigationBar () {
        
        // Create the navigation bar
        let navigationBar = UINavigationBar(frame: CGRectMake(0, 20, self.view.frame.size.width, 44)) // Offset by 20 pixels vertically to take the status bar into account
        navigationBar.barStyle = .Black
        navigationBar.delegate = self;
        
        // Create a navigation item with a title
        let navigationItem = UINavigationItem()
        navigationItem.title = "About PocketPark"
        navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont(name: "OtterFont", size: 25)!]
        
        navigationBar.items = [navigationItem]
        
        // Make the navigation bar a subview of the current view controller
        self.view.addSubview(navigationBar)
    }
    
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .TopAttached
    }
    
    @IBAction func feedbackButton(sender: AnyObject) {
        
//        let alertController = UIAlertController(
//            title: "Open Link in Safari?",
//            message: "Do you want to visit Pocket Theme Park on Twitter in Safari?",
//            preferredStyle: .Alert)
//        
//        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
//        alertController.addAction(cancelAction)
//        
//        let openAction = UIAlertAction(title: "Open Safari", style: .Default) { (action) in
            if let url = NSURL(string: "https://www.twitter.com/PocketThemePark") {
                UIApplication.sharedApplication().openURL(url)
            }
//        }
//        alertController.addAction(openAction)
//        presentViewController(alertController, animated: true, completion: nil)
        
    }
    
    @IBAction func acknowledgementsButtonPressed(sender: AnyObject) {
//        let alertController = UIAlertController(
//            title: "Open Link in Safari?",
//            message: "Do you want to view acknoledgements in Safari?",
//            preferredStyle: .Alert)
//        
//        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
//        alertController.addAction(cancelAction)
//        
//        let openAction = UIAlertAction(title: "Open Safari", style: .Default) { (action) in
            if let url = NSURL(string: "http://themeparkofeveryday.com/#theme-park-of-everyday-acknowledgements-and-license") {
                UIApplication.sharedApplication().openURL(url)
            }
//        }
//        alertController.addAction(openAction)
//        presentViewController(alertController, animated: true, completion: nil)
    }
    
    @IBAction func createOwnButtonPressed(sender: AnyObject) {
//        let alertController = UIAlertController(
//            title: "Open Link in Safari?",
//            message: "Do you want to view how to create an interactive in Safari?",
//            preferredStyle: .Alert)
//        
//        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
//        alertController.addAction(cancelAction)
//        
//        let openAction = UIAlertAction(title: "Open Safari", style: .Default) { (action) in
            if let url = NSURL(string: "http://themeparkofeveryday.com/#theme-park-of-everyday-getting-started") {
                UIApplication.sharedApplication().openURL(url)
            }
//        }
//        alertController.addAction(openAction)
//        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func mailComposeController(controller:MFMailComposeViewController, didFinishWithResult result:MFMailComposeResult, error:NSError) {
        switch result.value {
        case MFMailComposeResultCancelled.value:
            println("Mail cancelled")
        case MFMailComposeResultSaved.value:
            println("Mail saved")
        case MFMailComposeResultSent.value:
            println("Mail sent")
        case MFMailComposeResultFailed.value:
            println("Mail sent failure: \(error.localizedDescription)")
        default:
            break
        }
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
}
