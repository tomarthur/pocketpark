//
//  InteractionBeaconManager.swift
//  interactron
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
            locationManager!.startUpdatingLocation()
        case .NotDetermined:
            locationManager!.requestAlwaysAuthorization()
        case .Restricted, .Denied, .AuthorizedWhenInUse:
            NSNotificationCenter.defaultCenter().postNotificationName("LocationDisabled", object: nil)
            
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
                let nearestBeacon:CLBeacon = beacons[0] as CLBeacon
                
                if(nearestBeacon.proximity == lastProximity ||
                    nearestBeacon.proximity == CLProximity.Unknown) {
                        return;
                }
                
                lastProximity = nearestBeacon.proximity
                var beaconString = toString(nearestBeacon.major) + toString(nearestBeacon.minor)
                
                switch nearestBeacon.proximity {
                case CLProximity.Far:
                    return
                case CLProximity.Near:
                        sendLocalNotificationToStartInteraction(beaconString)
                case CLProximity.Immediate:
                        sendLocalNotificationToStartInteraction(beaconString)
                case CLProximity.Unknown:
                    return
                }
            } else {
                if(lastProximity == CLProximity.Unknown) {
                    return
                }
                lastProximity = CLProximity.Unknown
            }
    }
    
    func locationManager(manager: CLLocationManager!,
        didEnterRegion region: CLRegion!) {
            manager.startRangingBeaconsInRegion(region as CLBeaconRegion)
            manager.startUpdatingLocation()
            
            NSLog("You entered the region")
    }
    
    func locationManager(manager: CLLocationManager!,
        didExitRegion region: CLRegion!) {
            manager.stopRangingBeaconsInRegion(region as CLBeaconRegion)
            manager.stopUpdatingLocation()
            previouslySentNotifications.removeAll()
            sentNotification = false
            NSLog("You exited the region")
    }
    
    func pushLocalInteractiveAvailableNotification(friendlyName: String, bleName: String) {
        
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate

        var interactionNearbyNotification = UILocalNotification()
        interactionNearbyNotification.alertBody = "Control \(friendlyName) nearby."
        interactionNearbyNotification.hasAction = true
        interactionNearbyNotification.alertAction = "begin"
        interactionNearbyNotification.userInfo = [
            "friendlyName" : friendlyName,
            "bleName" : bleName
        ]
        
        // first check to make sure the interactive is on the list
        UIApplication.sharedApplication().scheduleLocalNotification(interactionNearbyNotification)

    }
    
    // check if beacon is for a known interactive and that it isn't ignored
    func sendLocalNotificationToStartInteraction(beaconString: String) {
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        
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
        case .NotDetermined:
            println("CL not yet determined")
        case .Restricted, .Denied, .AuthorizedWhenInUse:
            NSNotificationCenter.defaultCenter().postNotificationName("LocationDisabled", object: nil)
        default:
            println("CL unhandled error")
            
        }
    }
    
    
    
    func beaconIsIgnored(beaconString: String) -> Bool {
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate

        let alreadyExperienced = appDelegate.dataManager.isBeaconIgnored(beaconString)
        var recentlyNotified = false
        
        for (name, lastTime) in previouslySentNotifications {
            if (name == beaconString){
                let elapsedTime = NSDate().timeIntervalSinceDate(lastTime)

                if Int(elapsedTime) < 3600 {
                    recentlyNotified = true
                }
            }
        }

        if alreadyExperienced == true || recentlyNotified == true {
            println("ignored \(beaconString) beacon")
            return true
        } else{
            return false
        }
        
    }
    
}

