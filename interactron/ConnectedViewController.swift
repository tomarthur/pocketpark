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
    
    // Bluetooth Interactive Control
    var connectedBean: PTDBean?
    var connectedObjectInfo: PFObject!
    var foundInteractiveObjectID: String!
    var interactionMode: String?
    
    // Sensor Readings
    lazy var motionManager = CMMotionManager()
    var swipeRecognizer: UISwipeGestureRecognizer!
    
    // UI
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var explanation: UILabel!
    @IBOutlet weak var interactionType : UILabel!
    
    
    required init(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
        
    }
    
    func handleSwipes(sender: UISwipeGestureRecognizer){
        if sender.direction == .Down{
            println("Swiped Right, exit view")
            self.deactivateAllMotion()
            NSNotificationCenter.defaultCenter().postNotificationName("EndInteraction", object: nil)
            // Dismiss any modal view controllers.
            self.dismissViewControllerAnimated(true, completion:nil)
        }
    }
    
    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        println("loaded connected")
        
        swipeRecognizer = UISwipeGestureRecognizer(target: self, action: "handleSwipes:")
        self.view.addGestureRecognizer(swipeRecognizer)
        /* Swipes that are perfomed from the right to the left are to be detected to end connection to interactive */
        swipeRecognizer.direction = .Down
        swipeRecognizer.numberOfTouchesRequired = 1
        
        
        // get object from parse to populate UI and know how to communicate with it
        getInteractiveObject(foundInteractiveObjectID!)
        
        var backgroundColor: UIColor
        self.view.backgroundColor = .ITConnectedColor()
        
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
    
    func deactivateAllMotion(){
        
        motionManager.stopDeviceMotionUpdates()
        
    }
    
    func getInteractiveObject(foundInteractiveObjectID: String){
        var query = PFQuery(className: "installations")
        query.fromLocalDatastore()
        query.getObjectInBackgroundWithId(foundInteractiveObjectID) {
            (objectInfo: PFObject!, error: NSError!) -> Void in
            if (error == nil) {
                self.populateInteractiveInfo(objectInfo)
                println(objectInfo)
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
        updateUIWithInteractiveInfo()
        startInteraction()
        
    }
    
    func updateUIWithInteractiveInfo(){
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
        
        switch modeString{
            case "gyro-rotate":
                activateRotationMotion()
            case "shake":
                activateShakeDetect()
            case "sound":
                println("not yet implemented")
            case "compass":
                println("not yet implemented")
            case "light":
                println("not yet implemented")
            case "tap":
                println("not yet implemented")
            case "tilt-portrait":
                println("not yet implemented")
            case "barometer":
                println("not yet implemented")
            default:
                println("not yet implemented")
        }
    }
    
    func activateShakeDetect(){
        shakeDetectMode = true
    }
    
    var count = 0
    var shakeDetectMode = false
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent) {
        
        if motion == .MotionShake && shakeDetectMode == true {
            if count > 7 {
                count = 0
            }
            
            println("shake! \(count)")
            self.sendScratchDatatoBean(count)
            count++
            
        }
    }


    
}
