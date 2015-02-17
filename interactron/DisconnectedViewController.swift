//
//  DisconnectedViewController.swfit
//  interactron
//
//  Created by Tom Arthur on 2/16/15.
//  Copyright (c) 2015 Tom Arthur. All rights reserved.
//
//  Adapted from:
//  DisconnectedViewController.swift
//  Cool Beans
//  Created by Kyle on 11/14/14.
//  Copyright (c) 2014 Kyle Weiner. All rights reserved. 
//  Cool Beans is MIT Licensed.
//

import UIKit

class DisconnectedViewController: UIViewController, PTDBeanManagerDelegate {
    
    let connectedViewControllerSegueIdentifier = "ViewConnection"
    
    var manager: PTDBeanManager!
    var connectedBean: PTDBean? {
        didSet {
            if connectedBean == nil {
                self.beanManagerDidUpdateState(manager)
            } else {
                performSegueWithIdentifier(connectedViewControllerSegueIdentifier, sender: self)
            }
        }
    }
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        manager = PTDBeanManager(delegate: self)
        
        
        queryParseForInteractives()
        
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == connectedViewControllerSegueIdentifier {
            let vc = segue.destinationViewController as ConnectedViewController
            vc.connectedBean = connectedBean
            vc.connectedBean?.delegate = vc
        }
    }
    
    // MARK: PTDBeanManagerDelegate
    
    func beanManagerDidUpdateState(beanManager: PTDBeanManager!) {
        switch beanManager.state {
        case .Unsupported:
            UIAlertView(
                title: "Error",
                message: "This device does not support Bluetooth Low Energy.",
                delegate: self,
                cancelButtonTitle: "OK"
                ).show()
        case .Unknown:
            UIAlertView(
                title: "Error",
                message: "This device does is not able to use Bluetooth Low Energy at this time.",
                delegate: self,
                cancelButtonTitle: "OK"
                ).show()
        case .Unauthorized:
            UIAlertView(
                title: "Error",
                message: "Please give permission for Bluetooth in Settings.",
                delegate: self,
                cancelButtonTitle: "OK"
                ).show()
        case .PoweredOff:
            UIAlertView(
                title: "Error",
                message: "Please turn on Bluetooth.",
                delegate: self,
                cancelButtonTitle: "OK"
                ).show()
        case .PoweredOn:
            beanManager.startScanningForBeans_error(nil);
        default:
            break
        }
    }
    
    func beanManager(beanManager: PTDBeanManager!, didDiscoverBean bean: PTDBean!, error: NSError!) {
        println("DISCOVERED BEAN \nName: \(bean.name), UUID: \(bean.identifier) RSSI: \(bean.RSSI)")
//        if connectedBean == nil {
//            if bean.state == .Discovered {
//                manager.connectToBean(bean, error: nil)
//            }
//        }
    }
    
    func BeanManager(beanManager: PTDBeanManager!, didConnectToBean bean: PTDBean!, error: NSError!) {
        println("CONNECTED BEAN \nName: \(bean.name), UUID: \(bean.identifier) RSSI: \(bean.RSSI)")
        if connectedBean == nil {
            connectedBean = bean
        }
//        PFAnalytics.trackEvent("interactConnect", name:bean.name)
    }
    
    func beanManager(beanManager: PTDBeanManager!, didDisconnectBean bean: PTDBean!, error: NSError!) {
        println("DISCONNECTED BEAN \nName: \(bean.name), UUID: \(bean.identifier) RSSI: \(bean.RSSI)")
        
        // Dismiss any modal view controllers.
        presentedViewController?.dismissViewControllerAnimated(true, completion: { () in
            self.dismissViewControllerAnimated(true, completion: nil)
        })
        
        self.connectedBean = nil
    }
    
    
    // MARK: Parse Data Gathering
    
    func queryParseForInteractives() {
        
        // pull latest interactive objects from Parse
        var query = PFQuery(className:"installations")
        query.findObjectsInBackgroundWithBlock
            {
                (objects: [AnyObject]!, error: NSError!) -> Void in
                if error == nil
                {
                    PFObject.pinAllInBackground(objects)
                    println("pinned objects")
                } else {
                    var alert = UIAlertController(title: "Error", message: "Unable to retrieve interactives from the server.", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                }
        }
        
        debugPrintAllKnownInteractives()
    }
    
    func debugPrintAllKnownInteractives() {

        // liststhe names of all known interactive elemments found in the localstorage from Parse
        var query = PFQuery(className:"installations")
        query.fromLocalDatastore()
        
        query.findObjectsInBackgroundWithBlock
        {
            (objects: [AnyObject]!, error: NSError!) -> Void in
            if error != nil {
                // There was an error.
                var alert = UIAlertController(title: "Error", message: "Unable to retrieve interactives from the local device.", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            } else {
                println("known interactives:")
                for object in objects {
                    println(object["name"])
                }
            }
            self.knownInteractives()
        }
    }
    
    func knownInteractives(){
        
        // liststhe names of all known interactive elemments found in the localstorage from Parse
        var query = PFQuery(className:"installations")
        query.fromLocalDatastore()
        var interactivesObjects = query.findObjects() as [PFObject]
        
        println("now displaying from known interactives")
        for interactive in interactivesObjects {
            // Use staff as a standard PFObject now. e.g.
//            let firstName = staff.objectForKey("first_name")
            println(interactive.objectForKey("identifier"))
        }
        
    }

}

