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

class DisconnectedViewController: UIViewController, PTDBeanManagerDelegate, UITabBarDelegate {
    
    let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
    
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    
    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var settingsManualControlButton: UITabBarItem!
    @IBOutlet weak var infoButton: UITabBarItem!
    @IBOutlet weak var nearbyButton: UITabBarItem!
    
    
    var bluetoothIsReady = false
    var automaticMode = false
    var isConnecting = false
    var haltConnections = false

    
    var nearbyBLEInteractives = [String:PTDBean]()      // PTDBean objects detected in the area
    var connectedBeanObjectID: String?                  // Parse objectId for connected bean
    
    
    var manager: PTDBeanManager!
    var connectedBean: PTDBean? {
        didSet {
            if connectedBean == nil {
                self.beanManagerDidUpdateState(manager)
                updateMode(nil)

            } else {
                // present connected view when beacon connection established
                let connectedViewController:ConnectedViewController = ConnectedViewController(nibName: "ConnectedView", bundle: nil)
                
                //Pass identifers to connectedVC
                connectedViewController.connectedBean = connectedBean
                connectedViewController.foundInteractiveObjectID = connectedBeanObjectID
                
                let connectInfo = [
                    // Define ranges to bucket data points into meaningful segments
                    "interactiveName": toString(connectedBean?.name),
                    // Did the user filter the query?
                    "connectTime": toString(NSDate())
                ]
                
                // Send the dimensions to Parse along with the 'connect' event
                PFAnalytics.trackEvent("connect", dimensions:connectInfo)
                
                presentViewController(connectedViewController, animated: true, completion: nil)
                
                activityIndicator.stopAnimating()
               
            }
        }
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Assign tab bar item with titles
        let tabBarController = UITabBarController()
        tabBar.selectedItem = self.tabBar.items![1] as? UITabBarItem
        tabBar.tintColor = .ITConnectedColor()

        // when datastore and bluetooth are ready
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "startScanningForInteractives:",
            name: "readyToFind", object: nil)
        
        // get notification when user wants to end experience
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "endInteraction:",
            name: "EndInteraction", object: nil)
        
        // TO DO: Combine following two alerts to one function
        // when iBeacon of interactive is detected or manually selected on settings view
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "initiateConnectionFromManualRequest:",
            name: "startInteractionRequest", object: nil)
        // when iBeacon of interactive is detected or manually selected on settings view
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "initiateConnectionFromNotification:",
            name: "startInteractionFromNotification", object: nil)
        
        // when exiting settings view update behaviors
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateMode:",
            name: "updatedMode", object: nil)
        
        // when app is no longer in focus, disconnect
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "endInteraction:",
            name: UIApplicationDidEnterBackgroundNotification, object: nil)
        
        // when app is closing disconnect
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "endInteraction:",
            name: UIApplicationWillTerminateNotification, object: nil)
        
        // when location disabled
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "displayLocationAlert:",
            name: "LocationDisabled", object: nil)
        
        manager = PTDBeanManager(delegate: self)
        
        self.view.backgroundColor = .ITWelcomeColor()
    }
    
    
    override func viewDidAppear(animated: Bool) {
        tabBar.selectedItem = self.tabBar.items![1] as? UITabBarItem
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    // MARK: Navigation

    func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem!) {
        switch item.tag {
        case 0:
            // stop app from connecting while we are in map
            haltConnections = true
            mapButtonPressed()
            println("0")
        case 1:
            println("1")
        case 2:
            // stop app from connecting while we are in manual control
            haltConnections = true
            settingsButtonPressed()
            println("2")
        default:
            break
        }
        
    }
    
    func settingsButtonPressed() {
        // disconnect if connected
        if connectedBean != nil {
            manager.disconnectBean(connectedBean, error:nil)
        }
        
        let settingsViewController:SettingsViewController = SettingsViewController(
            nibName: "SettingsView",bundle: nil)
        
        // send current nearby BLE interactives
        settingsViewController.nearbyBLEInteractives = nearbyBLEInteractives
        
        settingsViewController.modalTransitionStyle = .FlipHorizontal
        presentViewController(settingsViewController, animated: true, completion: nil)

    }
    
    func mapButtonPressed() {
        // disconnect if connected
        if connectedBean != nil {
            manager.disconnectBean(connectedBean, error:nil)
        }
        
        let interactiveMapViewController:InteractiveMapViewController = InteractiveMapViewController(
            nibName: "InteractiveMap",bundle: nil)
         
        interactiveMapViewController.modalTransitionStyle = .FlipHorizontal
        presentViewController(interactiveMapViewController, animated: true, completion: nil)
        
    }

    
    func updateMode(notification: NSNotification?) {
        
        haltConnections = false
        
        if let automaticConnectionStatus = appDelegate.defaults.boolForKey(appDelegate.automaticConnectionKey) as Bool?
        {
            if automaticConnectionStatus == true {
                automaticMode = true
                activityIndicator.startAnimating()
                status.font = UIFont(name:"OtterFont", size: 25)
                status.sizeToFit()
                status.numberOfLines = 0
                status.text = "Discovering Experiences Nearby"
                
            } else {
                automaticMode = false
                activityIndicator.stopAnimating()
                status.font =  UIFont(name:"OtterFont", size: 25)
                status.sizeToFit()
                status.numberOfLines = 0
                status.text = "Automatic Contact Disabled. Press Nearby for Options.\n\(nearbyBLEInteractives.count) nearby"
                
            }
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
            bluetoothIsReady = true
            NSNotificationCenter.defaultCenter().postNotificationName("readyToFind", object: nil)
        default:
            break
        }
    }
    
    func startScanningForInteractives(notif: NSNotification)
    {
        if appDelegate.dataManager.dataStoreReady == true && bluetoothIsReady == true {
            println("Data is \(appDelegate.dataManager.dataStoreReady) and bluetooth is: \(bluetoothIsReady)")
            self.manager.startScanningForBeans_error(nil)
            updateMode(nil)
        }
    }
    
    func beanManager(beanManager: PTDBeanManager!, didDiscoverBean bean: PTDBean!, error: NSError!) {

        // add found interactive to dictionary
        if appDelegate.dataManager.isInteractiveKnown(toString(bean.name)) == true {
            
            nearbyBLEInteractives[bean.name] = bean
            NSNotificationCenter.defaultCenter().postNotificationName("AddedNewInteractive", object: self, userInfo: nearbyBLEInteractives)
            
        }
        
        // automatically connect if enabled, not ignored and app is in forground
        let appState : UIApplicationState = UIApplication.sharedApplication().applicationState
        if appState == UIApplicationState.Active {

            if connectedBean == nil && haltConnections == false && automaticMode == true
                && appDelegate.dataManager.isInteractiveIgnored(bean.identifier) == false {
                    
                    intiateConnectionIfInteractionValid(bean)
            }
        }
    }
    

    func BeanManager(beanManager: PTDBeanManager!, didConnectToBean bean: PTDBean!, error: NSError!) {
        println("CONNECTED BEAN \nName: \(bean.name), UUID: \(bean.identifier) RSSI: \(bean.RSSI)")
        
        if (error != nil){
            isConnecting = false
            UIAlertView(
                title: "Unable to Contact Interactive",
                message: "(didConnect Error) The experience isn't able to to start. Please try again later.",
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
    }
    
    func beanManager(beanManager: PTDBeanManager!, didDisconnectBean bean: PTDBean!, error: NSError!) {
        println("DISCONNECTED BEAN \nName: \(bean.name), UUID: \(bean.identifier) RSSI: \(bean.RSSI)")
        
        if (error != nil){
           println("error disconnecting")
           println(error)
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName("EndInteraction", object: nil)
        
        // Dismiss any modal view controllers.
        presentedViewController?.dismissViewControllerAnimated(true, completion: { () in
            self.dismissViewControllerAnimated(true, completion: nil)
        })
        
        self.connectedBeanObjectID = nil
        self.connectedBean = nil
        isConnecting = false

    }
    
    func intiateConnectionIfInteractionValid(bean: PTDBean!) {
        
        // check if the interactive is in the parse data store
        if appDelegate.dataManager.isInteractiveKnown(toString(bean.name)) == true {
            
            // check if Bean SDK still has detected the bean
            if bean.state == .Discovered{
                println("Attempting to connect to \(toString(bean.name))")
                
                // prevent attempts to connect to other interactives
                if (isConnecting == false){
                    isConnecting = true

                    activityIndicator.startAnimating()
                    var connectError : NSError?
                    
                    manager.connectToBean(bean, error: &connectError)
                    
                    // tell the user what we've found
                    status.text = "Contacting \(appDelegate.dataManager.knownInteractivesFromParseFriendlyNames[bean.name]!)"
                }
            } else {
                println("ERROR: cant find that bean")
                UIAlertView(
                    title: "Unable to Find Interactive",
                    message: "The experience isn't able to to start. Please try again later.",
                    delegate: self,
                    cancelButtonTitle: "OK"
                    ).show()
            }
        }
    }
    
    // end interaction by disconnecting and adding to temporary ignore list
    func endInteraction(notification: NSNotification) {
        println("end interaction notification in disconnected VC")
        // Dismiss any modal view controllers.
        presentedViewController?.dismissViewControllerAnimated(true, completion: { () in
            self.dismissViewControllerAnimated(true, completion: nil)
        })
        
        if connectedBean != nil {
            appDelegate.dataManager.previouslyExperiencedInteractivesToIgnore[toString(connectedBean!.name)] = connectedBean!.identifier!
            manager.disconnectBean(connectedBean, error:nil)
        }
    }
    
    // handles notification from beacon or settings page that a interaction is requested
    func initiateConnectionFromManualRequest(notification: NSNotification) {
        if let interactionInfo = notification.userInfo as? Dictionary<String, PTDBean>{
            println(interactionInfo)
            if let id = interactionInfo["beaconInteractionObject"] {
                intiateConnectionIfInteractionValid(id)
            }
        }
    }
    
    // handles notification from beacon or settings page that a interaction is requested
    func initiateConnectionFromNotification(notification: NSNotification) {
        if let interactionInfo = notification.userInfo as? Dictionary<String, String>{
            if let id = interactionInfo["beaconInteractionBLEName"] {
                findBeanObjectAndConnectFromBLEName(id)
            }
        }
    }
    
    func findBeanObjectAndConnectFromBLEName(bleName: String) {
        for (nearbyName, bean) in nearbyBLEInteractives {
            if bleName == nearbyName {
                intiateConnectionIfInteractionValid(bean)
            }
        }
    }
    
    func displayLocationAlert(notification: NSNotification?) {
        let alertController = UIAlertController(
            title: "Background Location Access Disabled",
            message: "In order to be notified about interactive experiences near you, please open this app's settings and set location access to 'Always'.",
            preferredStyle: .Alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let openAction = UIAlertAction(title: "Open Settings", style: .Default) { (action) in
            if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                UIApplication.sharedApplication().openURL(url)
            }
        }
        alertController.addAction(openAction)
        
        presentViewController(alertController, animated: true, completion: nil)
        
    }

    
    
}




