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
import IJReachability

class DisconnectedViewController: UIViewController, PTDBeanManagerDelegate {
    
    var knownInteractives = [String: String]()
    var connectedBeanObjectID: String?
    var dataStoreReady = false
    
    let connectedViewControllerSegueIdentifier = "goToConnectedView"
    
    var manager: PTDBeanManager!
    var connectedBean: PTDBean? {
        didSet {
            if connectedBean == nil {
                self.beanManagerDidUpdateState(manager)
            } else {
                // segue to connected view when beacon connection established
                performSegueWithIdentifier(connectedViewControllerSegueIdentifier, sender: self)
            }
        }
    }
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        manager = PTDBeanManager(delegate: self)
        
        queryParseForInteractiveObjects()
        
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
            println(connectedBeanObjectID)
            //Pass identifer of parse interactive object to connectedVC
            vc.foundInteractiveObjectID = connectedBeanObjectID
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
            // start checking for beans only after local data is loaded to check for beans
            if dataStoreReady == true{
                beanManager.startScanningForBeans_error(nil)
            } else {
                println("DataStore Not Ready")
            }
        default:
            break
        }
    }
    
    func beanManager(beanManager: PTDBeanManager!, didDiscoverBean bean: PTDBean!, error: NSError!) {
        println("DISCOVERED BEAN \nName: \(bean.name), UUID: \(bean.identifier) RSSI: \(bean.RSSI)")
        
        // check to see if the bean is on the interaction list
        // if it is on the list:
        //    - stop ranging for iBeacons
        //    - connect to it
        //    - load connected view controller
        //    - load sub view controller with information about how to operate
        
        // TO DO: FIX THIS
        // this is not restarting the find process if the parse data isn't complete
        if isInteractiveKnown(toString(bean.name)) == true {
            NSLog("Interactive is known!")
            if connectedBean == nil {
                if bean.state == .Discovered {
                    NSLog("Attempting to connect!")
                    connectedBeanObjectID = knownInteractives[bean.name]
                    manager.connectToBean(bean, error: nil)
                    
                }
            }
        }

    }
    
    func BeanManager(beanManager: PTDBeanManager!, didConnectToBean bean: PTDBean!, error: NSError!) {
        println("CONNECTED BEAN \nName: \(bean.name), UUID: \(bean.identifier) RSSI: \(bean.RSSI)")
        if connectedBean == nil {
            connectedBean = bean
        }
        
//        let dimensions = [
//            // Define ranges to bucket data points into meaningful segments
//            "beanName": bean.name,
//            // Did the user filter the query?
//            "rssi": bean.RSSI
//        ]
//        
//        // Send the dimensions to Parse along with the 'search' event
//        PFAnalytics.trackEvent("interactConnect", dimensions:dimensions)

    }
    
    func beanManager(beanManager: PTDBeanManager!, didDisconnectBean bean: PTDBean!, error: NSError!) {
        println("DISCONNECTED BEAN \nName: \(bean.name), UUID: \(bean.identifier) RSSI: \(bean.RSSI)")
        
        // Dismiss any modal view controllers.
        presentedViewController?.dismissViewControllerAnimated(true, completion: { () in
            self.dismissViewControllerAnimated(true, completion: nil)
        })
        self.connectedBeanObjectID = nil
        self.connectedBean = nil
        
//        do I need to start looking for beans here again?
    }
    
    
    
    // MARK: Parse Data
    
    // get most recent interactives from parse cloud
    func queryParseForInteractiveObjects() {
    
        // check for network availablity before requesting interactives from parse
        if (IJReachability.isConnectedToNetwork() == true) {
            
            // pull latest interactive objects from Parse
            var query = PFQuery(className:"installations")
            query.findObjectsInBackgroundWithBlock
                {
                    (objects: [AnyObject]!, error: NSError!) -> Void in
                    if error == nil
                    {
                        PFObject.pinAllInBackground(objects)
                    } else {
                        NSLog("Unable to add interactives to local data store")
                        NSLog("Error: %@ %@", error, error.userInfo!)
                    }
            }
            
            dictionaryOfInteractivesFromLocalDatastore()
        } else {
            
            // There was an error.
            UIAlertView(
                title: "No Internet Connection",
                message: "You have no network connection.",
                delegate: self,
                cancelButtonTitle: "OK"
                ).show()
            NSLog("Unable to access network, checking if localdatastore is avaialble")
            
            // still attempt to load data if it's available
            dictionaryOfInteractivesFromLocalDatastore()
            
        }
    }
    
    // make a dictionary of interactives pulled from parse local data
    func dictionaryOfInteractivesFromLocalDatastore() {

        // liststhe names of all known interactive elemments found in the localstorage from Parse
        var query = PFQuery(className:"installations")
        query.fromLocalDatastore()
        query.findObjectsInBackgroundWithBlock
        {
            (objects: [AnyObject]!, error: NSError!) -> Void in
            if error != nil {
                // There was an error.
                UIAlertView(
                    title: "No Interactives Known",
                    message: "Unable to retrieve interactives list.",
                    delegate: self,
                    cancelButtonTitle: "OK"
                    ).show()
                NSLog("Error: %@ %@", error, error.userInfo!)
                NSLog("Unable to find interactives in local data store")
                
            } else {
                var PFVersions = objects as [PFObject]
                for PFVersion in PFVersions {
                    self.knownInteractives[toString(PFVersion["blename"])] = toString(PFVersion.objectId)
                }
                self.dataStoreReady = true
                self.startScanningForInteractives()
            }
        }
    }
    
    func startScanningForInteractives()
    {
//        TO DO: FIX THIS
        println("start scanning")
        switch manager.state {
            case .Unsupported:
                break
            case .PoweredOn:
                self.manager.startScanningForBeans_error(nil)
            default:
                break
        }
        
    }
    
    // quickly check dictionary to see if interactive is in the known
    func isInteractiveKnown(foundInteractiveIdentifier: String) -> Bool{
        NSLog(foundInteractiveIdentifier)
        for (key, value) in knownInteractives {
            println("\(key) -> \(value)")
            if (key == foundInteractiveIdentifier)
            {
                return true
            }
        }
        return false
    }
}




