//
//  DisconnectedViewController.swfit
//  interactron
//
//  Created by Tom Arthur on 2/16/15.
//  Copyright (c) 2015 Tom Arthur. All rights reserved.
//
//  Contains code adapted from:
//  DisconnectedViewController.swift
//  Cool Beans
//  Created by Kyle on 11/14/14.
//  Copyright (c) 2014 Kyle Weiner. All rights reserved.
//

import UIKit

class DisconnectedViewController: UIViewController, PTDBeanManagerDelegate {
    
    let connectedViewControllerSegueIdentifier = "ViewConnection"
    
    var manager: PTDBeanManager!
    var connectedBean: PTDBean? {
        didSet {
            if connectedBean == nil {
                self.beanManagerDidUpdateState(manager)
            } else {
                performSegueWithIdentifier(connectedViewControllerSegueIdentifier, sender: self)
            }
        }
    }
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        manager = PTDBeanManager(delegate: self)
        queryParseForInteractives()
        // Do any additional setup after loading the view, typically from a nib.
        
//        var testObject = PFObject(className:"TestObject")
//        testObject["foo"] = "bar"
//        testObject.saveInBackground()
//        
//        NSException.raise("Exception", format:"Error: %@", arguments:getVaList(["nil"]))
        
        
        
//        var count = myArray.l
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == connectedViewControllerSegueIdentifier {
            let vc = segue.destinationViewController as ConnectedViewController
            vc.connectedBean = connectedBean
            vc.connectedBean?.delegate = vc
        }
    }
    
    // MARK: PTDBeanManagerDelegate
    
    func beanManagerDidUpdateState(beanManager: PTDBeanManager!) {
        switch beanManager.state {
        case .Unsupported:
            UIAlertView(
                title: "Error",
                message: "This device is unsupported.",
                delegate: self,
                cancelButtonTitle: "OK"
                ).show()
        case .PoweredOff:
            UIAlertView(
                title: "Error",
                message: "Please turn on Bluetooth.",
                delegate: self,
                cancelButtonTitle: "OK"
                ).show()
        case .PoweredOn:
            beanManager.startScanningForBeans_error(nil);
        default:
            break
        }
    }
    
    func beanManager(beanManager: PTDBeanManager!, didDiscoverBean bean: PTDBean!, error: NSError!) {
        println("DISCOVERED BEAN \nName: \(bean.name), UUID: \(bean.identifier) RSSI: \(bean.RSSI)")
//        if connectedBean == nil {
//            if bean.state == .Discovered {
//                manager.connectToBean(bean, error: nil)
//            }
//        }
    }
    
    func BeanManager(beanManager: PTDBeanManager!, didConnectToBean bean: PTDBean!, error: NSError!) {
        println("CONNECTED BEAN \nName: \(bean.name), UUID: \(bean.identifier) RSSI: \(bean.RSSI)")
        if connectedBean == nil {
            connectedBean = bean
        }
    }
    
    func beanManager(beanManager: PTDBeanManager!, didDisconnectBean bean: PTDBean!, error: NSError!) {
        println("DISCONNECTED BEAN \nName: \(bean.name), UUID: \(bean.identifier) RSSI: \(bean.RSSI)")
        
        // Dismiss any modal view controllers.
        presentedViewController?.dismissViewControllerAnimated(true, completion: { () in
            self.dismissViewControllerAnimated(true, completion: nil)
        })
        
        self.connectedBean = nil
    }
    
    func queryParseForInteractives() {
        
        var query = PFQuery(className:"installations")
        query.findObjectsInBackgroundWithBlock
            {
                (objects: [AnyObject]!, error: NSError!) -> Void in
                if error == nil
                {
                    PFObject.pinAllInBackground(objects)
                    println("pinned objects")
                } else {
                    var alert = UIAlertController(title: "Error", message: "Unable to retrieve interactives from the server", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                }
        }
        debugPrintAllKnownInteractives()
    }
    
    func debugPrintAllKnownInteractives() {
        
        var query = PFQuery(className:"installations")
        query.fromLocalDatastore()
        
        query.findObjectsInBackgroundWithBlock
            {
            (objects: [AnyObject]!, error: NSError!) -> Void in
            if error != nil {
                // There was an error.
                var alert = UIAlertController(title: "Error", message: "Unable to retrieve interactives from the local store", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            } else {
                println("objects should spit out here")
                for object in objects {
                    println(object["identifier"])
                }
            }
        }
    }
    
    func declareKnownInteractives(){
        
    }


}

