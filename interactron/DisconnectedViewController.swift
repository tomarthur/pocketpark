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
    
    let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
    
    var knownInteractives = [String: String]()
    var experiencedInteractivesToIgnore = [NSUUID]()
    var connectedBeanObjectID: String?
    var dataStoreReady = false
    var bluetoothReady = false
    var isConnecting = false
    
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
    
        
        
        // get notification when user wants to end experience
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "endInteraction:", name: "EndInteraction", object: nil)
        
        // get notification when iBeacon of interactive is detected
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "checkForInteractiveWithBeacon:", name: "InteractiveBeaconDetected", object: nil)
        
        // get notification when iBeacon of interactive is detected
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "startScanningForInteractives:", name: "readyToFind", object: nil)
        
        manager = PTDBeanManager(delegate: self)
        
        queryParseForInteractiveObjects()
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(animated: Bool) {
        
//        self.startScanningForInteractives(nil)
        
    }
    
    func checkForInteractiveWithBeacon(notif: NSNotification) {
        println("recieved beacon check request")
        
        if notif.name == "InteractiveBeaconDetected" {
            self.pushLocalInteractiveAvailableNotification()
            if let info = notif.userInfo as? Dictionary<String,NSNumber> {
                // Check if value present before using it
                if let s = info["major"] {
                    print(s)
                }
                else {
                    print("no value for key\n")
                }
            }
            else {
                print("wrong userInfo type")
            }
        }
    }
    
    func pushLocalInteractiveAvailableNotification() {
        
        var interactionNearbyNotification = UILocalNotification()
        interactionNearbyNotification.alertBody = "There's something you can control nearby."
        interactionNearbyNotification.hasAction = true
        interactionNearbyNotification.alertAction = "begin"
        
        // first check to make sure the interactive is on the list
        UIApplication.sharedApplication().scheduleLocalNotification(interactionNearbyNotification)
        
    }
    
    func endInteraction(notif: NSNotification) {
        println("recieved end of experience notification")
        
        if notif.name == "EndInteraction" {
            experiencedInteractivesToIgnore.append(connectedBean!.identifier!)
            manager.disconnectBean(connectedBean, error:nil)
        } else {
            println("got notification but not endinteraction")
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
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
            bluetoothReady = true
            NSNotificationCenter.defaultCenter().postNotificationName("readyToFind", object: nil)
//            NSNotificationCenter.defaultCenter().postNotificationName("readyToFind", object: nil)
        default:
            break
        }
    }
    
    func beanManager(beanManager: PTDBeanManager!, didDiscoverBean bean: PTDBean!, error: NSError!) {
        
        // TODO: FIX THIS
        
        if connectedBean == nil {
            if isInteractiveIgnored(bean.identifier) == false && isInteractiveKnown(toString(bean.name)) == true {
                
                    println("DISCOVERED KNOWN BEAN \nName: \(bean.name), UUID: \(bean.identifier) RSSI: \(bean.RSSI)")
            
                    if bean.state == .Discovered {
                        NSLog("Attempting to connect!")
                        if (isConnecting == false){
                            isConnecting = true
                            manager.connectToBean(bean, error: nil)
                        }
                    }
            
            } else {
                println("BEAN DISCOVERED BUT IGNORED OR NOT KNOWN \nName: \(bean.name), UUID: \(bean.identifier) RSSI: \(bean.RSSI)")
            }
                
        }
    }
    
    func BeanManager(beanManager: PTDBeanManager!, didConnectToBean bean: PTDBean!, error: NSError!) {
        println("CONNECTED BEAN \nName: \(bean.name), UUID: \(bean.identifier) RSSI: \(bean.RSSI)")
        
        if (error != nil){
            UIAlertView(
                title: "Unable to Connect",
                message: "Unable to connect to the interactive.",
                delegate: self,
                cancelButtonTitle: "OK"
                ).show()
            return
        }
        
        if connectedBean == nil {
            connectedBeanObjectID = knownInteractives[bean.name]
            connectedBean = bean
            isConnecting = false
            
        }
        
        
        // TODO: add analytics
    }
    
    func beanManager(beanManager: PTDBeanManager!, didDisconnectBean bean: PTDBean!, error: NSError!) {
        println("DISCONNECTED BEAN \nName: \(bean.name), UUID: \(bean.identifier) RSSI: \(bean.RSSI)")
        
        // Dismiss any modal view controllers.
        presentedViewController?.dismissViewControllerAnimated(true, completion: { () in
            self.dismissViewControllerAnimated(true, completion: nil)
        })
        
        self.connectedBeanObjectID = nil
        self.connectedBean = nil

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
                    message: "Connect to internet to retrieve interactives list.",
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
                NSNotificationCenter.defaultCenter().postNotificationName("readyToFind", object: nil)
            }
        }
    }
    
    func startScanningForInteractives(notif: NSNotification)
    {
        println("start scanning")
        
        if bluetoothReady == true && dataStoreReady == true {
            
                self.manager.startScanningForBeans_error(nil)

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
    
    // check to see if interactive is ignored because it's been played with
    func isInteractiveIgnored(foundInteractiveUUID: NSUUID) -> Bool {
        for ignoredUUID in experiencedInteractivesToIgnore
        {
            if (foundInteractiveUUID.isEqual(ignoredUUID))
            {
                return true
            }
        }
        return false
    }
}




