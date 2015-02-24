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

    var nearbyBLEInteractives = [NSUUID:String]()
    var connectedBeanObjectID: String?

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
            appDelegate.dataManager.previouslyExperiencedInteractivesToIgnore.append(connectedBean!.identifier!)
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
        println(nearbyBLEInteractives.count)
        settingsViewController.nearbyBLEInteractives = nearbyBLEInteractives
        
        var backgroundColor: UIColor
        settingsViewController.view.backgroundColor = .ITSettingsColor()
        settingsViewController.modalTransitionStyle = .FlipHorizontal

        presentViewController(settingsViewController, animated: true, completion: nil)

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
        default:
            break
        }
    }
    
    func startScanningForInteractives(notif: NSNotification)
    {
        println("start scanning")
        
        if bluetoothReady == true && appDelegate.dataManager.dataStoreReady == true {
            
            self.manager.startScanningForBeans_error(nil)
            activityIndicator.startAnimating()
            status.text = "Discovering Experiences Nearby"
            
        }
    }
    
    func beanManager(beanManager: PTDBeanManager!, didDiscoverBean bean: PTDBean!, error: NSError!) {
        
        // TODO: FIX THIS
        
        // add device to dictionary when discovered
        
        // periodically check if connected and connect to something we haven't before if it's around
        
        
        if appDelegate.dataManager.isInteractiveKnown(toString(bean.name)) == true {
            println("DISCOVERED KNOWN BEAN \nName: \(bean.name), UUID: \(bean.identifier) RSSI: \(bean.RSSI)")
            nearbyBLEInteractives[bean.identifier] = toString(bean.name)
        }
        
        if connectedBean == nil {
            intiateConnectionAfterInteractionCheck(bean)
        }
        
    }
    
    func intiateConnectionAfterInteractionCheck(bean: PTDBean!) {
        if appDelegate.dataManager.isInteractiveIgnored(bean.identifier) == false && appDelegate.dataManager.isInteractiveKnown(toString(bean.name)) == true {
            if bean.state == .Discovered {
                NSLog("Attempting to connect!")
                if (isConnecting == false){
                    isConnecting = true
                    manager.connectToBean(bean, error: nil)
                    // tell the user what we've found
                    status.text = "Contacting \(appDelegate.dataManager.knownInteractivesFromParseFriendlyNames[bean.name]!)"
                }
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
            connectedBeanObjectID = appDelegate.dataManager.knownInteractivesFromParse[bean.name]
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
    
    

}




