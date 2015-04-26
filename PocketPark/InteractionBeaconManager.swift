//
//  InteractionBeaconManager.swift
//  Pocket Theme Park
//
//
//
//  Created by Tom Arthur on 2/21/15.
//  Copyright (c) 2015 Tom Arthur. All rights reserved.
//

import Foundation


class InteractionBeaconManager: NSObject, CLLocationManagerDelegate {
    var locationManager: CLLocationManager?
    var lastProximity: CLProximity?
    var sentNotification = false
    
    var previouslySentNotifications = [String:NSDate]()
    
    func start () {

        locationManager = CLLocationManager()
        locationManager!.delegate = self
        locationManager!.pausesLocationUpdatesAutomatically = true

        if CLLocationManager.authorizationStatus() == .AuthorizedAlways {
           startUpdatingLocation()
        }

    }
    
    func startUpdatingLocation() {
        
        switch CLLocationManager.authorizationStatus() {
        case .AuthorizedAlways:
            // iBeacon Regions and Notification to find Interactive Elements enabled by LightBlue Bean
            let uuid = NSUUID(UUIDString: "A4955441-C5B1-4B44-B512-1370F02D74DE")
            let beaconIdentifier = NSBundle.mainBundle().bundleIdentifier!
            let beaconRegion:CLBeaconRegion = CLBeaconRegion(proximityUUID: uuid,
                identifier: beaconIdentifier)
            
            locationManager!.startMonitoringForRegion(beaconRegion)
            
            // TO DO: for demo only
            locationManager!.startRangingBeaconsInRegion(beaconRegion)

            locationManager!.startUpdatingLocation()
        case .NotDetermined:
            locationManager!.requestAlwaysAuthorization()
        case .Restricted, .Denied, .AuthorizedWhenInUse:
            NSNotificationCenter.defaultCenter().postNotificationName("LocationDisabled", object: nil)
            
        }
    }
    
    func startMonitoringForRegionOnly() {
        switch CLLocationManager.authorizationStatus() {
        case .AuthorizedAlways:
//            stopUpdatingLocation()
            // iBeacon Regions and Notification to find Interactive Elements enabled by LightBlue Bean
            let uuid = NSUUID(UUIDString: "A4955441-C5B1-4B44-B512-1370F02D74DE")
            let beaconIdentifier = NSBundle.mainBundle().bundleIdentifier!
            let beaconRegion:CLBeaconRegion = CLBeaconRegion(proximityUUID: uuid,
                identifier: beaconIdentifier)

            locationManager!.startMonitoringForRegion(beaconRegion)
//            locationManager!.startRangingBeaconsInRegion(beaconRegion)
            println("looking for region")
            
            
        case .NotDetermined:
            locationManager!.requestAlwaysAuthorization()
        case .Restricted, .Denied, .AuthorizedWhenInUse:
            NSNotificationCenter.defaultCenter().postNotificationName("LocationDisabled", object: nil)
        }
        
    }
    
    func stopUpdatingLocation() {
        
        locationManager!.stopUpdatingLocation()
    }
    
    func stopRangingBeacons() {
        let uuid = NSUUID(UUIDString: "A4955441-C5B1-4B44-B512-1370F02D74DE")
        let beaconIdentifier = NSBundle.mainBundle().bundleIdentifier!
        let beaconRegion:CLBeaconRegion = CLBeaconRegion(proximityUUID: uuid,
            identifier: beaconIdentifier)
        
        locationManager!.stopRangingBeaconsInRegion(beaconRegion as CLBeaconRegion)
    }
    
    func haveLocationPermission() -> Bool {
        switch CLLocationManager.authorizationStatus() {
        case .AuthorizedAlways:
            return true
        default:
            return false
        }
    }
    
    func requestAuthorization() {
        
        locationManager = CLLocationManager()
        
        switch CLLocationManager.authorizationStatus() {
        case .AuthorizedAlways:
            start()

        case .NotDetermined:
            locationManager!.requestAlwaysAuthorization()
        case .Restricted, .Denied, .AuthorizedWhenInUse:
             NSNotificationCenter.defaultCenter().postNotificationName("LocationDisabled", object: nil)
            
        }
        
    }
    
    func locationManager(manager: CLLocationManager!,
        didRangeBeacons beacons: [AnyObject]!,
        inRegion region: CLBeaconRegion!) {
            
            
            if(beacons.count > 0) {
                let nearestBeacon:CLBeacon = beacons[0] as! CLBeacon
                
                var beaconString = toString(nearestBeacon.major) + toString(nearestBeacon.minor)
                                    println("checking proximity")
                switch nearestBeacon.proximity {

                    case CLProximity.Unknown:
                        println("unknown")
                        return
                    default:
                        println("default")
                        sendLocalNotificationToStartInteraction(beaconString)
                        return
                    
                }
            }
    }
    
    func locationManager(manager: CLLocationManager!,
        didEnterRegion region: CLRegion!) {
            manager.startRangingBeaconsInRegion(region as! CLBeaconRegion)
            manager.startUpdatingLocation()

            NSLog("You entered the region")
    }
    
    func locationManager(manager: CLLocationManager!,
        didExitRegion region: CLRegion!) {
            manager.stopRangingBeaconsInRegion(region as! CLBeaconRegion)
            manager.stopUpdatingLocation()
            
            previouslySentNotifications.removeAll()
            sentNotification = false
            UIApplication.sharedApplication().cancelAllLocalNotifications();

            NSLog("You exited the region")
    }
    
    func pushLocalInteractiveAvailableNotification(friendlyName: String, bleName: String) {
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

        var interactionNearbyNotification = UILocalNotification()
        interactionNearbyNotification.alertBody = "Control \(friendlyName) nearby."
        interactionNearbyNotification.hasAction = true
        interactionNearbyNotification.alertAction = "begin"
        interactionNearbyNotification.soundName = "tone.aiff"
        interactionNearbyNotification.userInfo = [
            "friendlyName" : friendlyName,
            "bleName" : bleName
        ]
        
        // Send the dimensions to Parse along with the 'connect' event
        let notificationInfo = [
            // Define ranges to bucket data points into meaningful segments
            "interactiveFriendlyName": friendlyName,
            "interactiveBLEName": bleName,
            "notificationTime": toString(NSDate())
        ]
        PFAnalytics.trackEvent("notification", dimensions:notificationInfo)
        UIApplication.sharedApplication().cancelAllLocalNotifications();
        
        UIApplication.sharedApplication().scheduleLocalNotification(interactionNearbyNotification)

    }
    
    // check if beacon is for a known interactive and that it isn't ignored
    func sendLocalNotificationToStartInteraction(beaconString: String) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        // TODO: Add timeout to prevent multiple notifications
        let appState : UIApplicationState = UIApplication.sharedApplication().applicationState
        
        if appState != UIApplicationState.Active
            {
                
            if appDelegate.dataManager.isInteractiveKnown(beaconString) == true {
                if (beaconIsIgnored(beaconString) == false) {
                    for (value, key) in appDelegate.dataManager.knownInteractivesFromParseFriendlyNames{
                        if (value == beaconString){
                            println("send local notification")
                            
                            self.pushLocalInteractiveAvailableNotification(key, bleName: value)
                            previouslySentNotifications[beaconString] = NSDate()
                        }
                    }
                }
            }
        }
        
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch CLLocationManager.authorizationStatus(){
        case .AuthorizedAlways:
            startUpdatingLocation()
        case .Restricted, .Denied, .AuthorizedWhenInUse:
            NSNotificationCenter.defaultCenter().postNotificationName("LocationDisabled", object: nil)
        default:
            return
            
        }
    }
    
    
    
    func beaconIsIgnored(beaconString: String) -> Bool {
        
//        println("FIX THIS checking if ignored")
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

        let alreadyExperienced = appDelegate.dataManager.isBeaconIgnored(beaconString)
        var recentlyNotified = false
        
        if let lastNotified = previouslySentNotifications[beaconString] {
            let currentTime = NSDate()
            let elapsedTime = currentTime.timeIntervalSinceDate(lastNotified)
            println("Elapsed Time since Last Notification \(elapsedTime) seconds)")
            
            if elapsedTime < 7200 {
                println("registered in last 100 seconds")
                return true
            } else {
                println("ready to go")
                return false
            }
        }
        
        return false
    }
    
}

