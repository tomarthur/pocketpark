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

    var nearbyBLEInteractives = [NSUUID:Int]()
    var knownInteractivesFromParse = [String: String]()
    var knownInteractivesFromParseFriendlyNames = [String: String]()
    var previouslyExperiencedInteractivesToIgnore = [NSUUID]()
    var connectedBeanObjectID: String?
    var dataStoreReady = false
    var bluetoothReady = false
    var isConnecting = false
    
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var settingsButton: UIButton!
    
    
    
    var manager: PTDBeanManager!
    var connectedBean: PTDBean? {
        didSet {
            if connectedBean == nil {
                self.beanManagerDidUpdateState(manager)
                status.text = "Discovering New Experiences Nearby"
            } else {
                
            
                // present connected view when beacon connection established

                let connectedViewController:ConnectedViewController = ConnectedViewController(nibName: "ConnectedView", bundle: nil)
                
                //Pass identifer of parse interactive object to connectedVC
                connectedViewController.connectedBean = connectedBean
                connectedViewController.foundInteractiveObjectID = connectedBeanObjectID

                presentViewController(connectedViewController, animated: true, completion: nil)
            }
        }
    }
    
    
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
        
        var backgroundColor: UIColor
        self.view.backgroundColor = .ITWelcomeColor()
    }
    
    override func viewDidAppear(animated: Bool) {
        
        
    }
    
    func checkForInteractiveWithBeacon(notif: NSNotification) {
        // TODO: Implement iBeacon Check
        println("recieved beacon check request")
        
        if notif.name == "InteractiveBeaconDetected" {
            
            if let info = notif.userInfo as? Dictionary<String,NSNumber> {
                // Check if value present before using it
                if let s = info["major"] {
                    self.pushLocalInteractiveAvailableNotification(toString(s))
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
    
    func pushLocalInteractiveAvailableNotification(friendlyName: String) {
        
        var interactionNearbyNotification = UILocalNotification()
        interactionNearbyNotification.alertBody = "\(friendlyName) is ready to control nearby."
        interactionNearbyNotification.hasAction = true
        interactionNearbyNotification.alertAction = "begin"
        
        // first check to make sure the interactive is on the list
        UIApplication.sharedApplication().scheduleLocalNotification(interactionNearbyNotification)
        
    }
    
    func endInteraction(notif: NSNotification) {
        println("recieved end of experience notification")
        
        if notif.name == "EndInteraction" {
            previouslyExperiencedInteractivesToIgnore.append(connectedBean!.identifier!)
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
    
    @IBAction func settingsButtonPressed(sender: AnyObject) {
        println("you pressed!!!!!")
        
        // present connected view when beacon connection established
        
        let settingsViewController:SettingsViewController = SettingsViewController(nibName: "SettingsView", bundle: nil)
        
        var backgroundColor: UIColor
        settingsViewController.view.backgroundColor = .ITSettingsColor()
        settingsViewController.modalTransitionStyle = .FlipHorizontal
//        settingsViewController.modalPresentationStyle = .OverCurrentContext
        presentViewController(settingsViewController, animated: true, completion: nil)

    }
    
//    let connectedViewController:ConnectedViewController = ConnectedViewController(nibName: "ConnectedView", bundle: nil)
//    
//    //Pass identifer of parse interactive object to connectedVC
//    connectedViewController.connectedBean = connectedBean
//    connectedViewController.foundInteractiveObjectID = connectedBeanObjectID
//    
//    presentViewController(connectedViewController, animated: true, completion: nil)

    
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
        default:
            break
        }
    }
    
    func startScanningForInteractives(notif: NSNotification)
    {
        println("start scanning")
        
        if bluetoothReady == true && dataStoreReady == true {
            
            self.manager.startScanningForBeans_error(nil)
            activityIndicator.startAnimating()
            status.text = "Discovering Experiences Nearby"
            
        }
    }
    
    func beanManager(beanManager: PTDBeanManager!, didDiscoverBean bean: PTDBean!, error: NSError!) {
        
        // TODO: FIX THIS
        
        if connectedBean == nil {
            if isInteractiveIgnored(bean.identifier) == false && isInteractiveKnown(toString(bean.name)) == true {
                
                    println("DISCOVERED KNOWN BEAN \nName: \(bean.name), UUID: \(bean.identifier) RSSI: \(bean.RSSI)")

                    if bean.state == .Discovered {
                        nearbyBLEInteractives[bean.identifier] = Int(bean.RSSI)
                        NSLog("Attempting to connect!")
                        if (isConnecting == false){
                            isConnecting = true
                            manager.connectToBean(bean, error: nil)
                            // tell the user what we've found
                            status.text = "Contacting \(knownInteractivesFromParseFriendlyNames[bean.name]!)"
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
                title: "Unable to Contact Interactive",
                message: "The experience isn't able to to start. Please try again later.",
                delegate: self,
                cancelButtonTitle: "OK"
                ).show()
            return
        }
        
        if connectedBean == nil {
            connectedBeanObjectID = knownInteractivesFromParse[bean.name]
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
    
    
    // MARK: Handling Parse Data
    
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
                    self.knownInteractivesFromParse[toString(PFVersion["blename"])] = toString(PFVersion.objectId)
                    self.knownInteractivesFromParseFriendlyNames[toString(PFVersion["blename"])] = toString(PFVersion["name"])
                }
                println("known interactives")
                self.dataStoreReady = true
                NSNotificationCenter.defaultCenter().postNotificationName("readyToFind", object: nil)
            }
        }
    }
    

    
    // quickly check dictionary to see if interactive is in the known
    func isInteractiveKnown(foundInteractiveIdentifier: String) -> Bool{
        NSLog(foundInteractiveIdentifier)
        for (key, value) in knownInteractivesFromParse {
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
        for ignoredUUID in previouslyExperiencedInteractivesToIgnore
        {
            if (foundInteractiveUUID.isEqual(ignoredUUID))
            {
                return true
            }
        }
        return false
    }
}




