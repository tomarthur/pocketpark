//
//  SensorManager.swift
//  PocketPark
//
//  Created by Tom Arthur on 4/24/15.
//
//

import Foundation
import CoreMotion
import AVFoundation

class SensorManager: NSObject, PTDBeanDelegate, AVAudioRecorderDelegate {
    
    // Bluetooth Control
    var connectedBean: PTDBean?
    var connectedObjectInfo: PFObject!
    var foundInteractiveObjectID: String!
    var interactionMode: String!
    
    // Motion
    lazy var motionManager = CMMotionManager()
    var averageResults: Double = 0.0
    
    // Audio levels
    var audioRecorder: AVAudioRecorder?
    var loudnessTimer: NSTimer?
    var lowPassResults: Double = 0.0
    
    
    override init() {
        return
    }


    func sendScratchDatatoBean(scratchBank: Int, dataIn: Int){
        var convetedInteger = NSInteger(dataIn)
        let dataSend = NSData(bytes: &convetedInteger, length: sizeof(dataIn.dynamicType))
        
        var scratchNumber = scratchBank;
        
        connectedBean!.setScratchBank(Int(scratchNumber), data:dataSend)
        
        println("datain: \(dataIn) sentdata: \(dataSend) length: \(sizeof(dataIn.dynamicType))")
        
    }
    
    func startInteraction(bean: PTDBean, controlString: String){
        
        connectedBean = bean
        interactionMode = controlString
        
        switch interactionMode{
        case "gyro-rotate":
            activateRotationMotion(interactionMode)
        case "shake":
            activateShakeDetect()
        case "sound":
            askForMicrophonePermission()
        case "force":
            activateRotationMotion(interactionMode)
        case "rotationRate":
            activateRotationMotion(interactionMode)
        case "light":
            println("not yet implemented")
            return
        case "tap":
            println("not yet implemented")
            return
        case "tilt-portrait":
            println("not yet implemented")
            return
        case "compass":
            println("not yet implemented")
            return
        default:
            println("not yet implemented")
            return
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
                    println("data.gravity x:\(data.gravity.x), y:\(data.gravity.y), z:\(data.gravity.z)")
                    //                    println("Rotation in: \(rotation)")
                    //                    var mappedRotation = ((rotation - 0) * (180 - 0) / (-6.5 - 0) + 0)
                    var mappedRotation = (-(data.gravity.x) + 1)*90
                    println("mappedRotation: \(mappedRotation)")
                    var mappedRotationInt:Int = Int(mappedRotation)
                    
                    self?.sendScratchDatatoBean(1, dataIn: mappedRotationInt)
                } else if modeString == "force" {
                    let yForce = data.userAcceleration.y * 8
                    let yForceInt: Int = Int(yForce)
                    println("force rate")
                    
                    let alpha:Double = 0.05
                    var peakPowerForChannel:Double = pow(10, (0.05 * Double(yForce)))
                    self!.averageResults = alpha * peakPowerForChannel + (1.0 - alpha) * self!.averageResults
                    var newVal = self!.averageResults
                    
                    var averageVal = self!.averageResults
                    
                    //                    println("x \(data.userAcceleration.x)")
                    println(averageVal)
                    self?.sendScratchDatatoBean(1, dataIn: Int(averageVal))
                    //                    println("z \(data.userAcceleration.z)")
                    
                    
                } else if modeString == "rotationRate" {
                    println("rotation rate")
                    println("x \(data.rotationRate.x)")
                    println("y \(data.rotationRate.y)")
                    println("z \(data.rotationRate.z)")
                    
                    let zRotationInt:Int = Int(data.rotationRate.z)
                    let absoluteZRotation:Int = abs(zRotationInt)
                    println(absoluteZRotation)
                    self?.sendScratchDatatoBean(1, dataIn: absoluteZRotation)
                    
                } else if modeString == "compass" {
                    println("compass")
                    println(data.magneticField)
                }
                
            }
        } else {
            println("deviceMotion not available")
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
    
    func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent) {
        
        if motion == .MotionShake && shakeDetectMode == true {
            println("shake!")
            self.sendScratchDatatoBean(1, dataIn: 1)
            self.sendScratchDatatoBean(1, dataIn: 0)
        }
    }
    
    ////////////////////////////////////////
    // AUDIO
    ////////////////////////////////////////
    
    func audioError() {
        self.endInteraction()
        NSNotificationCenter.defaultCenter().postNotificationName("audioError", object: nil)
    }
    
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
                                println("allowed")
                                self?.startListeningToAudioLoudness()
                            } else {
                                self?.endInteraction()
                                NSNotificationCenter.defaultCenter().postNotificationName("audioPermission", object: nil)
                            }
                        }
                    }
                    
                } else {
                    println("Couldn't start audio session")
                    println("no session")
                    audioError()
                }
        } else {
            println("no category")
            audioError()
            if let audioError = error{
                println("An error occured in setting the audio" + "session category. Error = \(audioError)")
            }
            
        }
    }
    
    func startListeningToAudioLoudness(){
        var error: NSError?
        
        let audioRecordingURL = self.audioRecordingPath()
        
        audioRecorder = AVAudioRecorder(URL: audioRecordingURL,
            settings: audioRecordingSettings() as [NSObject : AnyObject], error: &error)
        
        if let recorder = audioRecorder{
            recorder.delegate = self
            
            if recorder.prepareToRecord() && recorder.record(){
                recorder.meteringEnabled = true
                
                //                NSNotificationCenter.defaultCenter().addObserver(self, selector: "endAudioInteraction:",
                //                    name: "EndInteraction", object: nil)
                
                startAudioUpdateTimer()
                
                println("Successuly started record")
            } else {
                
                //                audioError()println("Failed to record.")
                audioRecorder = nil
            }
        } else {
            audioError()
            println("Failed to create audio recorder instance")
        }
    }
    
    
    // for some reason, not always starting levels check when asking for permission first. this fixed it.
    func startAudioUpdateTimer() {
        
        let delayInSeconds = 0.5
        let delayInNanoSeconds = dispatch_time(DISPATCH_TIME_NOW, Int64(delayInSeconds * Double(NSEC_PER_SEC)))
        
        dispatch_after(delayInNanoSeconds, dispatch_get_main_queue(), {
            
            self.audioAfterDelay()
        })
    }
    
    func audioAfterDelay() {
        self.loudnessTimer = NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector:("getLevels"), userInfo: nil, repeats: true)
    }
    
    
    func getLevels(){
        
        if let recorder = audioRecorder{
            
            recorder.updateMeters()
            let alpha:Double = 0.09
            var peakPowerForChannel:Double = pow(10, (0.05 * Double(recorder.peakPowerForChannel(0))))
            lowPassResults = alpha * peakPowerForChannel + (1.0 - alpha) * lowPassResults
            var newVal = lowPassResults * 2
            
            var averageVal = lowPassResults
            var mappedValues = ((newVal - 0.03) * (255 - 0) / (2.00 - 0.03) + 0)
            println("lowpass in \(newVal), mapped: \(mappedValues)")
            sendScratchDatatoBean(1, dataIn: Int(mappedValues))
            newVal = 0
        } else {
            audioError()
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
        
        println("ending audio")
        delay(0.15){
        NSNotificationCenter.defaultCenter().postNotificationName("EndInteraction", object: nil)
        }
        
    }
    
    func endAudioInteraction(){
        
        loudnessTimer?.invalidate()
        
        if let recorder = audioRecorder{
            recorder.stop()
            
        }
        
    }
    
    func endInteraction() {
        
        
        switch interactionMode{
            case "gyro-rotate":
                self.deactivateAllMotion()
                NSNotificationCenter.defaultCenter().postNotificationName("EndInteraction", object: nil)
            case "shake":
                self.deactivateAllMotion()
                NSNotificationCenter.defaultCenter().postNotificationName("EndInteraction", object: nil)
            case "sound":
                endAudioInteraction()
            case "force":
                self.deactivateAllMotion()
                NSNotificationCenter.defaultCenter().postNotificationName("EndInteraction", object: nil)
            case "rotationRate":
                self.deactivateAllMotion()
                NSNotificationCenter.defaultCenter().postNotificationName("EndInteraction", object: nil)
            case "light":
                NSNotificationCenter.defaultCenter().postNotificationName("EndInteraction", object: nil)
                println("not yet implemented")
                return
            case "tap":
                NSNotificationCenter.defaultCenter().postNotificationName("EndInteraction", object: nil)
                println("not yet implemented")
                return
            case "tilt-portrait":
                NSNotificationCenter.defaultCenter().postNotificationName("EndInteraction", object: nil)
                println("not yet implemented")
                return
            case "compass":
                NSNotificationCenter.defaultCenter().postNotificationName("EndInteraction", object: nil)
                println("not yet implemented")
                return
            default:
                NSNotificationCenter.defaultCenter().postNotificationName("EndInteraction", object: nil)
                return
        }
        
        
    }
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }

    
}