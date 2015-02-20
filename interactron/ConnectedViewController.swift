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
import CoreMotion


class ConnectedViewController: UIViewController, PTDBeanDelegate {
    
    let refreshControl = UIRefreshControl()
    
    var connectedBean: PTDBean?
    var connectedObjectInfo: PFObject?
    var foundInteractiveObjectID: String?
    var interactionMode: String?
    
    lazy var motionManager = CMMotionManager()
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var explanation: UILabel!
    @IBOutlet weak var interactionType : UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getInteractiveObject(foundInteractiveObjectID!)
        
    }
    
    func strToDataWithTrail(message:String) ->NSData {
        let messageWithTrail = message + String(UnicodeScalar(extraDigit.x))
        extraDigit.x = (extraDigit.x < 255 ? extraDigit.x + 1 : 0)
        return NSData(data: messageWithTrail.dataUsingEncoding(NSUTF8StringEncoding)!)
        
    }
    
    func activateRotationMotion()
    {
        if motionManager.deviceMotionAvailable{
            println("deviceMotion available")
            motionManager.deviceMotionUpdateInterval = 0.2
            motionManager.startDeviceMotionUpdatesToQueue(NSOperationQueue.mainQueue()) {
                [weak self] (data: CMDeviceMotion!, error: NSError!) in
                
                let rotation = atan2(data.gravity.x, data.gravity.y) - M_PI
                println(rotation)
                
                var mappedRotation = ((rotation - 0) * (180 - 0) / (-6.5 - 0) + 0)
                var integer1 = Int(mappedRotation)
//                var rotationStringHex = NSString(format:"%2X", mappedRotation)
//                var rotationStringInt = NSString(format:"%i", mappedRotation)
//
                var random = NSInteger(integer1) //(1-100)
                let dataSend = NSData(bytes: &random, length: sizeof(integer1.dynamicType))
    
                var scratchNumber = 1;
                self?.connectedBean?.setScratchBank(Int(scratchNumber), data:dataSend)
                
                println("rotation: \(rotation) mapped: \(mappedRotation) sentdata: \(dataSend)")
                
                
            }
        } else {
            println("deviceMotion not available")
        }
        
    }
    
    
    //workaround for lack of/broken class variables. This stores the change digit to append to strToDataWithTrail
    struct extraDigit {
        static var x:UInt8 = 0
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
        startInteraction()
        
    }
    
    func updateUIWithInfo(){
        var nonOptional = connectedObjectInfo!
        name.text = toString(nonOptional["name"])
        explanation.text = toString(nonOptional["explanation"])
        interactionType.text = toString(nonOptional["control"])
        
    }
    
    func startInteraction() {
        var nonOptional = connectedObjectInfo!
        
        interactionMode(toString(nonOptional["control"]))
        
    }
    
    func interactionMode(modeString: String){
        
        if (modeString == "gyro-rotate"){
            println("activating gyro interaction mode")
            activateRotationMotion()
        } else {
            println("invalid interaction mode")
        }
        
    }
    
    func sendScratchDatatoBean(){
        

        
    }


    
}
