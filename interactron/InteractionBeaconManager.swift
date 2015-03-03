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
        // iBeacon Regions and Notification to find Interactive Elements enabled by LightBlue Bean
        let uuid = NSUUID(UUIDString: "A4955441-C5B1-4B44-B512-1370F02D74DE")
        let beaconIdentifier = NSBundle.mainBundle().bundleIdentifier!
        let beaconRegion:CLBeaconRegion = CLBeaconRegion(proximityUUID: uuid,
            identifier: beaconIdentifier)

        locationManager = CLLocationManager()

        if(locationManager!.respondsToSelector("requestAlwaysAuthorization")) {
            locationManager!.requestAlwaysAuthorization()
        }
        locationManager!.delegate = self

        locationManager!.pausesLocationUpdatesAutomatically = true

        locationManager!.startMonitoringForRegion(beaconRegion)
        locationManager!.startRangingBeaconsInRegion(beaconRegion)
        locationManager!.startUpdatingLocation()

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
            sentNotification = false
            NSLog("You exited the region")
    }
    
    func pushLocalInteractiveAvailableNotification(friendlyName: String, bleName: String) {
        
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate

        var interactionNearbyNotification = UILocalNotification()
        interactionNearbyNotification.alertBody = "Play with \(friendlyName) nearby."
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
                //if (beaconIsIgnored(beaconString) == false) {
                    for (value, key) in appDelegate.dataManager.knownInteractivesFromParseFriendlyNames{
                        if (value == beaconString){
                            println("send local notification")
                            
                            self.pushLocalInteractiveAvailableNotification(key, bleName: value)
                            previouslySentNotifications[beaconString] = NSDate()
                        }
                    }
                //}
            }
        }
        
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch CLLocationManager.authorizationStatus(){
        case .Authorized:
            println("CL Authorized")
        case .AuthorizedWhenInUse:
            println("CL authorized when in use")
        case .Denied:
            println("CL Denied")
        case .NotDetermined:
            println("CL not determined")
        case .Restricted:
            println("CL restricted")
        default:
            println("CL unhandled error")
            
        }
    }
    
    
    
//    func beaconIsIgnored(beaconString: String) -> Bool {
//        let currentTime = NSDate()
//        let calendar = NSCalendar.currentCalendar()
//        let comps = NSDateComponents()
//        
//        comps.minute = 5
//        
//        let date2 = calendar.dateByAddingComponents(comps, toDate: NSDate(), options: NSCalendarOptions.allZeros)
//        
//        if dueDate.compare(date2!) == NSComparisonResult.OrderedDescending
//        {
//            NSLog("not due within a week");
//        } else if dueDate.compare(date2!) == NSComparisonResult.OrderedAscending
//        {
//            NSLog("due within a week");
//        } else
//        {
//            NSLog("due in exactly a week (to the second, this will rarely happen in practice)");
//        }
//        
//    }
    
}

