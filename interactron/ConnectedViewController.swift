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
    
//    let refreshControl = UIRefreshControl()
    
    // Bluetooth Interactive Control
    var connectedBean: PTDBean?
    var connectedObjectInfo: PFObject?
    var foundInteractiveObjectID: String?
    var interactionMode: String?
    
    // Sensor Readings
    lazy var motionManager = CMMotionManager()
    
    // UI
    let disconnectedViewControllerSegueIdentifier = "unwindToDisconnectedViewController"
    var swipeRecognizer: UISwipeGestureRecognizer!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var explanation: UILabel!
    @IBOutlet weak var interactionType : UILabel!
    
    
    required init(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
        swipeRecognizer = UISwipeGestureRecognizer(target: self, action: "handleSwipes:")
    }
    
    func handleSwipes(sender: UISwipeGestureRecognizer){
        if sender.direction == .Left{
            println("Swiped Left")
            // Dismiss any modal view controllers.
            self.dismissViewControllerAnimated(true, completion: {});
        }
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == disconnectedViewControllerSegueIdentifier {
//            let vc = segue.destinationViewController as ConnectedViewController
//            vc.connectedBean = connectedBean
//            vc.connectedBean?.delegate = vc
            println("detected return to disconnect")
//            //Pass identifer of parse interactive object to connectedVC
//            vc.foundInteractiveObjectID = connectedBeanObjectID
        }
        println("detected return to disconnect")
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Swipes that are perfomed from the right to the left are to be detected to end connection to interactive */
        swipeRecognizer.direction = .Left
        swipeRecognizer.numberOfTouchesRequired = 1
        view.addGestureRecognizer(swipeRecognizer)
        
        // get object from parse to populate UI and know how to communicate with it
        getInteractiveObject(foundInteractiveObjectID!)
        
    }
    

    
    
    func sendScratchDatatoBean(dataIn: Int){
        var convetedInteger = NSInteger(dataIn)
        let dataSend = NSData(bytes: &convetedInteger, length: sizeof(dataIn.dynamicType))
        
        var scratchNumber = 1;
        
        connectedBean?.setScratchBank(Int(scratchNumber), data:dataSend)
        
        println("datain: \(dataIn) sentdata: \(dataSend) length: \(sizeof(dataIn.dynamicType))")
        
    }
    
    func activateRotationMotion()
    {
        if motionManager.deviceMotionAvailable{
            println("deviceMotion available")
            motionManager.deviceMotionUpdateInterval = 0.2
            motionManager.startDeviceMotionUpdatesToQueue(NSOperationQueue.mainQueue()) {
                [weak self] (data: CMDeviceMotion!, error: NSError!) in
                
                let rotation = atan2(data.gravity.x, data.gravity.y) - M_PI
                
                var mappedRotation = ((rotation - 0) * (180 - 0) / (-6.5 - 0) + 0)
                var mappedRotationInt:Int = Int(mappedRotation)
                
                self?.sendScratchDatatoBean(mappedRotationInt)
            }
        } else {
            println("deviceMotion not available")
        }
        
    }
    
    
    func getInteractiveObject(foundInteractiveObjectID: String){
        var query = PFQuery(className: "installations")
        query.fromLocalDatastore()
        query.getObjectInBackgroundWithId(foundInteractiveObjectID) {
            (objectInfo: PFObject!, error: NSError!) -> Void in
            if (error == nil) {
                self.populateInteractiveInfo(objectInfo)
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
    
    func populateInteractiveInfo(parseInteractiveObject: PFObject) {

        connectedObjectInfo = parseInteractiveObject
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
    
    // determine the method stored for the interaction
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
    



    
}
