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

class ConnectedViewController: UIViewController{
    
    // Bluetooth Control
    var connectedBean: PTDBean?
    var connectedObjectInfo: PFObject!
    var foundInteractiveObjectID: String!
    var interactionMode: String?
    
    var sensorManager = SensorManager()
    
    // Swipe
    var swipeRecognizer: UISwipeGestureRecognizer!
      
    // UI
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var explanation: UILabel!
    @IBOutlet weak var swipeToEndButton: UIButton!
    
    func handleSwipes(sender: UISwipeGestureRecognizer){
        if sender.direction == .Down{
        
            endInteraction()
        }
    }
    
    @IBAction func endButtonPress(sender: AnyObject) {
        endInteraction()
    }
    
    required init(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
        
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
        
        // get object from parse to populate UI and know how to communicate with it
        getInteractiveObject(foundInteractiveObjectID!)
        
        /* Swipes that are perfomed from the top to the bottom are to be detected to end connection to interactive */
        swipeRecognizer = UISwipeGestureRecognizer(target: self, action: "handleSwipes:")
        self.view.addGestureRecognizer(swipeRecognizer)
        swipeRecognizer.direction = .Down
        swipeRecognizer.numberOfTouchesRequired = 1
        
        self.view.backgroundColor = .ITConnectedColor()
    }
    
    override func viewWillDisappear(animated: Bool)
    {
        super.viewWillDisappear(animated)
        sensorManager.endInteraction()
    }
    
    
    func endInteraction() {
        
        var objectInfo = connectedObjectInfo!
        var currentMode = toString(objectInfo["control"]!)
        

        sensorManager.endInteraction()
    }

    func getInteractiveObject(foundInteractiveObjectID: String){
        var query = PFQuery(className: "installations")
        query.fromLocalDatastore()
        query.getObjectInBackgroundWithId(foundInteractiveObjectID) {
            (objectInfo: PFObject?, error: NSError?) -> Void in
            if (error == nil) {
                self.populateInteractiveInfo(objectInfo!)
            } else {
                // There was an error.
                var unableToInteractAlert = UIAlertController(title: "Unable to Interact",
                    message: "Unable to retrieve installation information.",
                    preferredStyle: UIAlertControllerStyle.Alert)
                unableToInteractAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                self.showViewController(unableToInteractAlert, sender: nil)
                
                self.endInteraction()
                NSLog("Unable to find interactive in local data store")
            }
        }
    }
    
    func populateInteractiveInfo(parseInteractiveObject: PFObject) {

        connectedObjectInfo = parseInteractiveObject
        
        updateUIWithInteractiveInfo()
        startInteraction()
        
    }
    
    func updateUIWithInteractiveInfo(){
        var nonOptional = connectedObjectInfo!
        name.text = toString(nonOptional["name"]!)
        name.font = UIFont(name:"OtterFont", size: 45)
        name.numberOfLines = 0; //will wrap text in new line
        name.sizeToFit()
        explanation.text = toString(nonOptional["explanation"]!)
        explanation.numberOfLines = 0; //will wrap text in new line
        explanation.sizeToFit()
        //interactionType.text = toString(nonOptional["control"])
        
    }
    
    // determine the method stored for the interaction
    func startInteraction() {
        var objectInfo = connectedObjectInfo!

        sensorManager.startInteraction(connectedBean!, controlString: toString(objectInfo["control"]!))
    }
    
        
    
}
