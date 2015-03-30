//
//  DataManager.swift
//  interactron
//
//  Handles interactions with Parse data
//
//  Created by Tom Arthur on 2/23/15.
//  Copyright (c) 2015 Tom Arthur. All rights reserved.
//

import Foundation
import IJReachability

class DataManager: NSObject {
    
    var knownInteractivesFromParse = [String: String]()
    var knownInteractivesFromParseFriendlyNames = [String: String]()
    var knownInteractivesFromParseWithGeopoints = [String: PFGeoPoint]()
    var previouslyExperiencedInteractivesToIgnore = [String: NSUUID]()
    var dataStoreReady = false
    var networkTimer = NSTimer()
    
    func start () {
        networkTimer = NSTimer.scheduledTimerWithTimeInterval(20.0, target: self, selector: Selector("networkDelay"), userInfo: nil, repeats: false)
        queryParseForInteractiveObjects()
    }
    
    func retrieveUpdates() {
        queryParseForInteractiveObjects()
    }
    
    // MARK: Handling Parse Data

    // get most recent interactives from parse cloud
    func queryParseForInteractiveObjects() {
        
//        //println("calling queryParseForInteractiveObjects")
        // check for network availablity before requesting interactives from parse
        if (IJReachability.isConnectedToNetwork() == true) {
            // pull latest interactive objects from Parse
            var query = PFQuery(className:"installations")
            query.findObjectsInBackgroundWithBlock
                {
                    (objects: [AnyObject]!, error: NSError!) -> Void in
                    if error == nil
                    {
//                        //println("found all parse objects")
                        PFObject.pinAllInBackground(objects, block: { (success, error) -> Void in
                            if !success {
                               NSNotificationCenter.defaultCenter().postNotificationName("parseError", object: nil)
                            } else {
                               self.dictionaryOfInteractivesFromLocalDatastore()
                            }
                        })
                        
                        self.networkTimer.invalidate()
                    } else {
                        NSNotificationCenter.defaultCenter().postNotificationName("parseError", object: nil)
                        
                        NSLog("Unable to add interactives to local data store")
                        NSLog("Error: %@ %@", error, error.userInfo!)
                    }
            }
            
            
        } else {
//            //println("No network")
            NSNotificationCenter.defaultCenter().postNotificationName("noNetwork", object: nil)
            self.networkTimer.invalidate()
            // still attempt to load data if it's available
            dictionaryOfInteractivesFromLocalDatastore()
        }
    }
    
    func checkNetwork()
    {
//        //println("in data manager, check network")
        if (IJReachability.isConnectedToNetwork() == false)
        {
//            //println("in data manager, check network false")
            NSNotificationCenter.defaultCenter().postNotificationName("noNetwork", object: nil)
        }
        else
        {
//            //println("in data manager, check network true")
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
                    NSNotificationCenter.defaultCenter().postNotificationName("parseError", object: nil)
                    
                } else {
                    var PFVersions = objects as [PFObject]
                    for PFVersion in PFVersions {
                        self.knownInteractivesFromParse[toString(PFVersion["blename"])] = toString(PFVersion.objectId)
                        self.knownInteractivesFromParseFriendlyNames[toString(PFVersion["blename"])] = toString(PFVersion["name"])
                      
                    }
                    self.dictionaryOfInteractivesWithGeoPoints()
                    self.dataStoreReady = true
                    
                    NSNotificationCenter.defaultCenter().postNotificationName("readyToFind", object: nil)
                }
        }
    }
    
    func dictionaryOfInteractivesWithGeoPoints(){

        // lists names of all known interactive elemments found in the localstorage from Parse
        var query = PFQuery(className:"installations")
        query.fromLocalDatastore()
        
        query.findObjectsInBackgroundWithBlock
            {
                (objects: [AnyObject]!, error: NSError!) -> Void in
                if error != nil {
                    // There was an error.
                    NSNotificationCenter.defaultCenter().postNotificationName("noGeopoints", object: nil)
                } else {
                    var PFVersions = objects as [PFObject]
                    for PFVersion in PFVersions {
                        self.knownInteractivesFromParseWithGeopoints[toString(PFVersion["name"])] = PFVersion["location"] as? PFGeoPoint
                    }
                    NSNotificationCenter.defaultCenter().postNotificationName("GeoPointDictionaryReady", object: nil)
                }
        }
    }
    
    // quickly check dictionary to see if interactive is in the known
    func isInteractiveKnown(foundInteractiveIdentifier: String) -> Bool{
        for (key, value) in knownInteractivesFromParse {
            if (key == foundInteractiveIdentifier)
            {
                return true
            }
        }
        return false
    }
    
    // check to see if interactive is ignored because it's been played with
    func isInteractiveIgnored(foundInteractiveUUID: NSUUID) -> Bool {
        for (blename, ignoredUUID) in previouslyExperiencedInteractivesToIgnore
        {
            if (foundInteractiveUUID.isEqual(ignoredUUID))
            {
                return true
            }
        }
        return false
    }
    
    func isBeaconIgnored(foundInteractiveBeacon: String) -> Bool {
        for (blename, ignoredUUID) in previouslyExperiencedInteractivesToIgnore
        {
            if (foundInteractiveBeacon.isEqual(blename))
            {
                return true
            }
        }
        return false
    }
    
    func networkDelay() {
        NSNotificationCenter.defaultCenter().postNotificationName("networkDelay", object: nil)
    }
}