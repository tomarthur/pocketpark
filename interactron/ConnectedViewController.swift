//
//  ConnectedViewController.swift
//  interactron
//
//  Created by Tom Arthur on 2/16/15.
//  Copyright (c) 2015 Tom Arthur. All rights reserved.
//
//  Adapted from:
//  ConnectedViewController.swift
//  Cool Beans
//  Created by Kyle on 11/14/14.
//  Copyright (c) 2014 Kyle Weiner. All rights reserved.
//  Cool Beans is MIT Licensed.
//

import UIKit


class ConnectedViewController: UIViewController, PTDBeanDelegate {
    
    let refreshControl = UIRefreshControl()
    
    var connectedBean: PTDBean?
    var connectedObjectInfo: PFObject?
    var foundInteractiveObjectID: String?
    var interactionMode: String
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var explanation: UILabel!
    @IBOutlet weak var interactionType : UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getInteractiveObject(foundInteractiveObjectID!)

    }
    

    
    func getInteractiveObject(foundInteractiveObjectID: String){
        var query = PFQuery(className: "installations")
        query.fromLocalDatastore()
        query.getObjectInBackgroundWithId(foundInteractiveObjectID) {
            (objectInfo: PFObject!, error: NSError!) -> Void in
            if (error == nil) {
                self.populateObjectInfo(objectInfo)
            } else {
                // There was an error.
                UIAlertView(
                    title: "Error",
                    message: "Unable to retrieve interactive.",
                    delegate: self,
                    cancelButtonTitle: "OK"
                    ).show()
                NSLog("Error: %@ %@", error, error.userInfo!)
                NSLog("Unable to find interactive in local data store")
            }
        
        }
    }
    
    func populateObjectInfo(parseInfo: PFObject) {

        connectedObjectInfo = parseInfo
        println(connectedObjectInfo)
        updateUIWithInfo()
        
    }
    
    func updateUIWithInfo(){
        var nonOptional = connectedObjectInfo!
        name.text = toString(nonOptional["name"])
        explanation.text = toString(nonOptional["explanation"])
        interactionType.text = toString(nonOptional["control"])
        
    }
    
    func interactionMode(modeString: String){
        
        if (modeString == "gyro-rotate"){
            
            
        } else {
            
        }
        
        
    }


    
}
