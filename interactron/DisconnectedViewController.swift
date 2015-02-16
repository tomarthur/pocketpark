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
        // Do any additional setup after loading the view, typically from a nib.
        
//        var testObject = PFObject(className:"TestObject")
//        testObject["foo"] = "bar"
//        testObject.saveInBackground()
//        
//        NSException.raise("Exception", format:"Error: %@", arguments:getVaList(["nil"]))
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    func beanManagerDidUpdateState(beanManager: PTDBeanManager!) {
        if beanManager.state == BeanManagerState.PoweredOn {
            beanManager.startScanningForBeans_error(nil)
        }
    }
//
//    func BeanManager(beanManager: PTDBeanManager!, didDiscoverBean bean: PTDBean!, error: NSError!) {
//        let identifier = bean.identifier
//        NSLog("%@", identifier)
//    }
//    
//    func BeanManager(beanManager: PTDBeanManager!, didConnectToBean bean: PTDBean!, error: NSError!) {
//        
//    }
//    
//    func BeanManager(beanManager: PTDBeanManager!, didDisconnectBean bean: PTDBean!, error: NSError!) {
//        
//    }

}

