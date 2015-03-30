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
import AVFoundation


class ConnectedViewController: UIViewController, PTDBeanDelegate, AVAudioRecorderDelegate{
    
    // Bluetooth Control
    var connectedBean: PTDBean?
    var connectedObjectInfo: PFObject!
    var foundInteractiveObjectID: String!
    var interactionMode: String?
    
    // Swipe
    var swipeRecognizer: UISwipeGestureRecognizer!
    
    // Motion
    lazy var motionManager = CMMotionManager()
    var averageResults: Double = 0.0
    
    // Audio levels
    var audioRecorder: AVAudioRecorder?
    var loudnessTimer: NSTimer?
    var lowPassResults: Double = 0.0
    
    // UI
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var explanation: UILabel!
    @IBOutlet weak var swipeToEndButton: UIButton!
    
    func handleSwipes(sender: UISwipeGestureRecognizer){
        if sender.direction == .Down{
            
            self.deactivateAllMotion()
            endInteraction()
            
        }
    }
    
    @IBAction func endButtonPress(sender: AnyObject) {
        self.deactivateAllMotion()
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
        //println("loaded connected")
        
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
        //println("view will disappear")
    }
    
    
    func endInteraction() {
        
        NSNotificationCenter.defaultCenter().postNotificationName("EndInteraction", object: nil)
        // Dismiss view controllers.
        self.dismissViewControllerAnimated(true, completion:nil)
        
    }
    
    func sendScratchDatatoBean(scratchBank: Int, dataIn: Int){
        var convetedInteger = NSInteger(dataIn)
        let dataSend = NSData(bytes: &convetedInteger, length: sizeof(dataIn.dynamicType))
        
        var scratchNumber = scratchBank;
        
        connectedBean?.setScratchBank(Int(scratchNumber), data:dataSend)
        
        //println("datain: \(dataIn) sentdata: \(dataSend) length: \(sizeof(dataIn.dynamicType))")
        
    }
    
    
    func getInteractiveObject(foundInteractiveObjectID: String){
        var query = PFQuery(className: "installations")
        query.fromLocalDatastore()
        query.getObjectInBackgroundWithId(foundInteractiveObjectID) {
            (objectInfo: PFObject!, error: NSError!) -> Void in
            if (error == nil) {
                self.populateInteractiveInfo(objectInfo)
                //println(objectInfo)
            } else {
                // There was an error.
                var unableToInteractAlert = UIAlertController(title: "Unable to Interact",
                    message: "Unable to retrieve installation information.",
                    preferredStyle: UIAlertControllerStyle.Alert)
                unableToInteractAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                self.showViewController(unableToInteractAlert, sender: nil)
                
                self.endInteraction()
                NSLog("Unable to find interactive in local data store")
                NSLog("Error: %@ %@", error, error.userInfo!)
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
        name.text = toString(nonOptional["name"])
        name.font = UIFont(name:"OtterFont", size: 45)
        name.numberOfLines = 0; //will wrap text in new line
        name.sizeToFit()
        explanation.text = toString(nonOptional["explanation"])
        explanation.numberOfLines = 0; //will wrap text in new line
        explanation.sizeToFit()
//        interactionType.text = toString(nonOptional["control"])
        
    }
    
    // determine the method stored for the interaction
    func startInteraction() {
        // TODO: Is this right?
        var objectInfo = connectedObjectInfo!
        interactionMode(toString(objectInfo["control"]))
        
    }
    
    func interactionMode(modeString: String){
        
        switch modeString{
            case "gyro-rotate":
                activateRotationMotion(modeString)
            case "shake":
                activateShakeDetect()
            case "sound":
                askForMicrophonePermission()
            case "force":
                activateRotationMotion(modeString)
            case "rotationRate":
                activateRotationMotion(modeString)
            case "light":
                //println("not yet implemented")
                return
            case "tap":
                //println("not yet implemented")
                return
            case "tilt-portrait":
                //println("not yet implemented")
                return
            case "compass":
                //println("not yet implemented")
                return
            default:
                //println("not yet implemented")
                return
        }
    }
    
    ////////////////////////////////////////
    // Motion
    ////////////////////////////////////////
    
    func activateRotationMotion(modeString: String)
    {
        if motionManager.deviceMotionAvailable{
            //println("deviceMotion available")
            motionManager.deviceMotionUpdateInterval = 0.2
            motionManager.startDeviceMotionUpdatesToQueue(NSOperationQueue.mainQueue()) {
                [weak self] (data: CMDeviceMotion!, error: NSError!) in
                
                if modeString == "gyro-rotate" {
                    let rotation = atan2(data.gravity.x, data.gravity.y) - M_PI
                    //println("data.gravity x:\(data.gravity.x), y:\(data.gravity.y), z:\(data.gravity.z)")
//                    //println("Rotation in: \(rotation)")
//                    var mappedRotation = ((rotation - 0) * (180 - 0) / (-6.5 - 0) + 0)
                    var mappedRotation = (-(data.gravity.x) + 1)*90
                    //println("mappedRotation: \(mappedRotation)")
                    var mappedRotationInt:Int = Int(mappedRotation)
                    
                    self?.sendScratchDatatoBean(1, dataIn: mappedRotationInt)
                } else if modeString == "force" {
                    let yForce = data.userAcceleration.y * 8
                    let yForceInt: Int = Int(yForce)
                    //println("force rate")
                    
                    let alpha:Double = 0.05
                    var peakPowerForChannel:Double = pow(10, (0.05 * Double(yForce)))
                    self!.averageResults = alpha * peakPowerForChannel + (1.0 - alpha) * self!.averageResults
                    var newVal = self!.averageResults
                    
                    var averageVal = self!.averageResults
                    
//                    //println("x \(data.userAcceleration.x)")
                    //println(averageVal)
                    self?.sendScratchDatatoBean(1, dataIn: Int(averageVal))
//                    //println("z \(data.userAcceleration.z)")
                    
                
                } else if modeString == "rotationRate" {
                    //println("rotation rate")
                    //println("x \(data.rotationRate.x)")
                    //println("y \(data.rotationRate.y)")
                    //println("z \(data.rotationRate.z)")
                    
                    let zRotationInt:Int = Int(data.rotationRate.z)
                    let absoluteZRotation:Int = abs(zRotationInt)
                    //println(absoluteZRotation)
                    self?.sendScratchDatatoBean(1, dataIn: absoluteZRotation)
                    
                } else if modeString == "compass" {
                    //println("compass")
                    //println(data.magneticField)
                }
                
            }
        } else {
            //println("deviceMotion not available")
        }
        
    }
    
    func easedForce(force: Double){
        
        
    }

    
    func activateDeviceHeading(){
        
        
    }
    
    func deactivateAllMotion(){
        
        motionManager.stopDeviceMotionUpdates()
        
    }

    
    ////////////////////////////////////////
    // Shake
    ////////////////////////////////////////
    
    func activateShakeDetect(){
        shakeDetectMode = true
    }
    
    var shakeDetectMode = false
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent) {
        
        if motion == .MotionShake && shakeDetectMode == true {

            //println("shake!")
            self.sendScratchDatatoBean(1, dataIn: 1)
            self.sendScratchDatatoBean(1, dataIn: 0)
        }
    }
    
    
    
    ////////////////////////////////////////
    // AUDIO
    ////////////////////////////////////////
    
    func askForMicrophonePermission() {
        //println("getting into permissions")
        var error: NSError?
        let session = AVAudioSession.sharedInstance()
 
        if session.setCategory(AVAudioSessionCategoryRecord,
            withOptions: .DuckOthers, error: &error) {
                if session.setMode(AVAudioSessionModeMeasurement, error: &error){
                    if session.setActive(true, error: nil){
                        session.requestRecordPermission{[weak self](allowed: Bool) in
                            if allowed {
                                self?.startListeningToAudioLoudness()
                            } else {
                                var unableToInteractAlert = UIAlertController(title: "Microphone Required",
                                    message: "Please grant access to the microphone to experience this installation.",
                                    preferredStyle: UIAlertControllerStyle.Alert)
                                unableToInteractAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                                self?.showViewController(unableToInteractAlert, sender: nil)
                                self?.endInteraction()
                            }
                        }
                    }

                } else {
                 //println("Couldn't start audio session")
                endInteraction()
                }
        } else {
            endInteraction()
            if let audioError = error{
                //println("An error occured in setting the audio" + "session category. Error = \(audioError)")
            }
            
        }
    }

    func startListeningToAudioLoudness(){
        var error: NSError?
        
        let audioRecordingURL = self.audioRecordingPath()

        audioRecorder = AVAudioRecorder(URL: audioRecordingURL,
            settings: audioRecordingSettings(), error: &error)

        if let recorder = audioRecorder{
            recorder.delegate = self
            
            if recorder.prepareToRecord() && recorder.record(){
                recorder.meteringEnabled = true
                
                NSNotificationCenter.defaultCenter().addObserver(self, selector: "endAudioInteraction:",
                    name: "EndInteraction", object: nil)
                
                let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
                dispatch_sync(queue, startAudioUpdateTimer)
                
                //println("Successuly started record")
            } else {
                //println("Failed to record.")
                audioRecorder = nil
            }
        } else {
            //println("Failed to create audio recorder instance")
        }
    }
    
    func startAudioUpdateTimer() {
        
        loudnessTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "getLevels:", userInfo: nil, repeats: true)
    }
    

    func getLevels(timer: NSTimer){
        if let recorder = audioRecorder{
            recorder.updateMeters()
            let alpha:Double = 0.09
            var peakPowerForChannel:Double = pow(10, (0.05 * Double(recorder.peakPowerForChannel(0))))
            lowPassResults = alpha * peakPowerForChannel + (1.0 - alpha) * lowPassResults
            var newVal = lowPassResults * 2

            var averageVal = lowPassResults
            var mappedValues = ((newVal - 0.03) * (255 - 0) / (2.00 - 0.03) + 0)
            //println("lowpass in \(newVal), mapped: \(mappedValues)")
            sendScratchDatatoBean(1, dataIn: Int(mappedValues))
            newVal = 0
        } else {

        }

    }
    
    func audioRecordingPath() -> NSURL {
        return NSURL.fileURLWithPath("/dev/null")!
    }
    
    func audioRecordingSettings() -> NSDictionary {
        
        return [
            AVFormatIDKey: kAudioFormatAppleLossless,
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.High.rawValue as NSNumber
        ]

    }
    
    func audioRecorderBeginInterruption(recorder: AVAudioRecorder!) {
        //println("interuption started")
        endInteraction()
    }
    
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder!, successfully flag: Bool) {
        
    }
    
    func endAudioInteraction(notification: NSNotification){
        
        loudnessTimer?.invalidate()

        if let recorder = audioRecorder{

                recorder.stop()
        }
        
    }
    
    
}
