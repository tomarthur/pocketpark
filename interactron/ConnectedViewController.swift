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
    
    var sensorInterface = SensorManager()
    
    // Bluetooth Control
    var connectedBean: PTDBean?
    var connectedObjectInfo: PFObject!
    var foundInteractiveObjectID: String!
    var interactionMode: String?
    
    // Swipe
    var swipeRecognizer: UISwipeGestureRecognizer!
    
    // Motion
    lazy var motionManager = CMMotionManager()
    
    // Audio levels
    var audioRecorder: AVAudioRecorder?
    var loudnessTimer: NSTimer?
    var lowPassResults: Double = 0.0
    
    // UI
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var explanation: UILabel!
    @IBOutlet weak var interactionType : UILabel!
    
    func handleSwipes(sender: UISwipeGestureRecognizer){
        if sender.direction == .Down{
            println("Swiped Right, exit view")
            self.deactivateAllMotion()
            endInteraction()
            
        }
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
        println("view will disappear")
    }
    
    
    func endInteraction() {
        
        NSNotificationCenter.defaultCenter().postNotificationName("EndInteraction", object: nil)
        // Dismiss view controllers.
        self.dismissViewControllerAnimated(true, completion:nil)
        
    }
    
    func sendScratchDatatoBean(dataIn: Int){
        var convetedInteger = NSInteger(dataIn)
        let dataSend = NSData(bytes: &convetedInteger, length: sizeof(dataIn.dynamicType))
        
        var scratchNumber = 1;
        
        connectedBean?.setScratchBank(Int(scratchNumber), data:dataSend)
        
        println("datain: \(dataIn) sentdata: \(dataSend) length: \(sizeof(dataIn.dynamicType))")
        
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
        name.numberOfLines = 0; //will wrap text in new line
        name.sizeToFit()
        explanation.text = toString(nonOptional["explanation"])
        explanation.numberOfLines = 0; //will wrap text in new line
        explanation.sizeToFit()
        interactionType.text = toString(nonOptional["control"])
        
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
    
    ////////////////////////////////////////
    // Motion
    ////////////////////////////////////////
    
    func activateRotationMotion(modeString: String)
    {
        if motionManager.deviceMotionAvailable{
            println("deviceMotion available")
            motionManager.deviceMotionUpdateInterval = 0.2
            motionManager.startDeviceMotionUpdatesToQueue(NSOperationQueue.mainQueue()) {
                [weak self] (data: CMDeviceMotion!, error: NSError!) in
                
                if modeString == "gyro-rotate" {
                    let rotation = atan2(data.gravity.x, data.gravity.y) - M_PI
                    
                    var mappedRotation = ((rotation - 0) * (180 - 0) / (-6.5 - 0) + 0)
                    var mappedRotationInt:Int = Int(mappedRotation)
                    
                    self?.sendScratchDatatoBean(mappedRotationInt)
                } else if modeString == "magnetometer" {
                    
                }
                
            }
        } else {
            println("deviceMotion not available")
        }
        
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
    
    
    
    ////////////////////////////////////////
    // AUDIO
    ////////////////////////////////////////
    
    func askForMicrophonePermission() {
        println("getting into permissions")
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
                                UIAlertView(
                                    title: "Microphone Required",
                                    message: "Please grant access to the microphone to experience this interactive.",
                                    delegate: self,
                                    cancelButtonTitle: "OK"
                                    ).show()
                                println("user didn't give permission")
                                self?.endInteraction()
                            }
                        }
                    }

                } else {
                 println("Couldn't start audio session")
                endInteraction()
                }
        } else {
            endInteraction()
            if let audioError = error{
                println("An error occured in setting the audio" + "session category. Error = \(audioError)")
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
                
                println("Successuly started record")
            } else {
                println("Failed to record.")
                audioRecorder = nil
            }
        } else {
            println("Failed to create audio recorder instance")
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
            println("lowpass in \(newVal), mapped: \(mappedValues)")
            sendScratchDatatoBean(Int(mappedValues))
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
        println("interuption started")
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
