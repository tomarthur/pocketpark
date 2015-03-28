//
//  AboutViewController.swift
//  
//
//  Created by Tom Arthur on 2/23/15.
//
//

import UIKit
import MessageUI

class AboutViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var titleText: UILabel!
    @IBOutlet weak var subtitleText: UILabel!
    @IBOutlet weak var explanationText: UILabel!
    @IBOutlet weak var createOwnButton: UIButton!
    @IBOutlet weak var feedbackButton: UIButton!
    @IBOutlet weak var acknowledgementsButton: UIButton!
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleText.font = UIFont(name:"OtterFont", size: 35)
        titleText.adjustsFontSizeToFitWidth = true
        
        explanationText.textAlignment = .Center;
        
        self.view.backgroundColor = .ITWelcomeColor()
    }
    
    @IBAction func feedbackButton(sender: AnyObject) {
        
        let alertController = UIAlertController(
            title: "Open Link in Safari?",
            message: "Do you want to visit Pocket Theme Park on Twitter in Safari?",
            preferredStyle: .Alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let openAction = UIAlertAction(title: "Open Safari", style: .Default) { (action) in
            if let url = NSURL(string: "https://www.twitter.com/PocketThemePark") {
                UIApplication.sharedApplication().openURL(url)
            }
        }
        alertController.addAction(openAction)
        presentViewController(alertController, animated: true, completion: nil)
        
    }
    
    @IBAction func acknowledgementsButtonPressed(sender: AnyObject) {
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
