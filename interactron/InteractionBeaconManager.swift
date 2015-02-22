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

    
    func start () {
        println("\n\nhere in interaction beacon manager\n\n")
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
    
    func sendLocalNotificationToStartInteraction(major: NSNumber!, minor: NSNumber!) {
        
        var beacoNotificationDict: [String:NSNumber] = ["Major" : major, "Minor" : minor]
        NSNotificationCenter.defaultCenter().postNotificationName("InteractiveBeaconDetected", object: self, userInfo: beacoNotificationDict)
        
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
                
                switch nearestBeacon.proximity {
                case CLProximity.Far:
                    return
                case CLProximity.Near:
                    if (sentNotification == false) {
                        sendLocalNotificationToStartInteraction(nearestBeacon.major, minor: nearestBeacon.minor)
                        sentNotification = true
                    }
                case CLProximity.Immediate:
                    if (sentNotification == false) {
                        sendLocalNotificationToStartInteraction(nearestBeacon.major, minor: nearestBeacon.minor)
                        sentNotification = true
                        println(nearestBeacon.major)
                        println(nearestBeacon.minor)
                    }
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
}

