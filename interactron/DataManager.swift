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
    var previouslyExperiencedInteractivesToIgnore = [NSUUID]()
    var dataStoreReady = false
    
    func start () {
        queryParseForInteractiveObjects()
    }
    
    func retrieveUpdates() {
        queryParseForInteractiveObjects()
    }
    
    // MARK: Handling Parse Data

    // get most recent interactives from parse cloud
    func queryParseForInteractiveObjects() {
        
        // check for network availablity before requesting interactives from parse
        if (IJReachability.isConnectedToNetwork() == true) {
            println("getting to query")
            // pull latest interactive objects from Parse
            var query = PFQuery(className:"installations")
            query.findObjectsInBackgroundWithBlock
                {
                    (objects: [AnyObject]!, error: NSError!) -> Void in
                    if error == nil
                    {
                        PFObject.pinAllInBackground(objects)
                        self.dictionaryOfInteractivesFromLocalDatastore()
                    } else {
                        NSLog("Unable to add interactives to local data store")
                        NSLog("Error: %@ %@", error, error.userInfo!)
                    }
            }
            
            
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
        println("getting to dictionary")
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
                        println(PFVersion)
                    }

                    self.dataStoreReady = true
                    NSNotificationCenter.defaultCenter().postNotificationName("readyToFind", object: nil)
                }
        }
    }
    
    func dictionaryOfInteractivesWithGeoPoints(){
        println("getting the geo points")
        // liststhe names of all known interactive elemments found in the localstorage from Parse
        var query = PFQuery(className:"installations")
        query.fromLocalDatastore()
        
        query.findObjectsInBackgroundWithBlock
            {
                (objects: [AnyObject]!, error: NSError!) -> Void in
                if error != nil {
                    // There was an error.
                    UIAlertView(
                        title: "No Geopoints Found",
                        message: "Huh?.",
                        delegate: self,
                        cancelButtonTitle: "OK"
                        ).show()
                    NSLog("Error: %@ %@", error, error.userInfo!)
                    NSLog("Unable to find geopoints")
                    
                } else {
                    var PFVersions = objects as [PFObject]
                    for PFVersion in PFVersions {
      
                        
                        self.knownInteractivesFromParseWithGeopoints[toString(PFVersion["name"])] = PFVersion["location"] as PFGeoPoint
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