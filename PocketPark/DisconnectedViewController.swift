//
//  DisconnectedViewController.swfit
//  PocketPark
//
//  Created by Tom Arthur on 2/16/15.
//  Copyright (c) 2015 Tom Arthur. All rights reserved.
//
//  Adapted from:
//  DisconnectedViewController.swift
//  Cool Beans
//  Created by Kyle on 11/14/14.
//  Copyright (c) 2014 Kyle Weiner. All rights reserved. 
//  Cool Beans is MIT Licensed.
//

import UIKit
import IJReachability
import MBProgressHUD


class DisconnectedViewController: UIViewController, PTDBeanManagerDelegate,  UITableViewDataSource, UITableViewDelegate {
    
    let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
    
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var interactivesNearbyTable: UITableView!
    var refreshControl:UIRefreshControl!
    var didAnimateCell:[NSIndexPath: Bool] = [:]
    
    var tableCellsReady = false
    var bluetoothIsReady = false
    var isConnecting = false
    var haltConnections = false
    
    var connectedBeanObjectID: String?                      // Parse objectId for connected bean
    var nearbyBLEInteractives = [String:PTDBean]()          // PTDBean objects detected in the area
    var nearbyBLEInteractivesLastSeen = [String:NSDate]()   // Time of last discovery
    
    var nearbyInteractivesFriendlyArray = [String]()        // Table view content
    var readyToDisplayInteractives = [String:PFObject]()    // Table view content

    
    var manager: PTDBeanManager!
    var connectedBean: PTDBean? {
        didSet {
            if connectedBean == nil {
                self.beanManagerDidUpdateState(manager)

            } else {
                // present connected view when beacon connection established
                let connectedViewController:ConnectedViewController = ConnectedViewController(nibName: "ConnectedView", bundle: nil)
                
                //Pass identifers to connectedVC
                connectedViewController.connectedBean = connectedBean
                connectedViewController.foundInteractiveObjectID = connectedBeanObjectID
                
                // Send the dimensions to Parse along with the 'connect' event
                let connectInfo = [
                    // Define ranges to bucket data points into meaningful segments
                    "interactiveName": toString(connectedBean?.name),
                    // Did the user filter the query?
                    "connectTime": toString(NSDate())
                ]
                PFAnalytics.trackEvent("connect", dimensions:connectInfo)
                
                MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
                presentViewController(connectedViewController, animated: true, completion: nil)
            }
        }
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        manager = PTDBeanManager(delegate: self)
        
        // Notifications

        // when datastore and bluetooth are ready start scanning
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "startScanningForInteractives:",
            name: "readyToFind", object: nil)
        
        // when new interactive is discovered add to table view
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "addNewInteractive:",
            name: "AddedNewInteractive", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "findBeanObjectAndConnectFromFriendlyName:",
            name: "connectFriendly", object: nil)
        
        // when iBeacon of interactive is detected
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "initiateConnectionFromNotification:",
            name: "startInteractionFromNotification", object: nil)
        
        // get notification when user wants to end experience
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "endInteraction:",
            name: "EndInteraction", object: nil)
        
        // when app is no longer in focus, disconnect
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "endInteraction:",
            name: UIApplicationDidEnterBackgroundNotification, object: nil)
        
        // when app is no longer in focus, clear cache of found items
         NSNotificationCenter.defaultCenter().addObserver(self, selector: "clearCacheOfInteractives:",
            name: UIApplicationDidEnterBackgroundNotification, object: nil)
        
        // when app is returning to focus
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshTable:",
            name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        // when app is closing disconnect
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "endInteraction:",
            name: UIApplicationWillTerminateNotification, object: nil)
        
        // when location disabled warn user
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "displayLocationAlert:",
            name: "LocationDisabled", object: nil)
        
        // alert when network isn't avaialble
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "displayNoNetworkAlert:",
            name: "noNetwork", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "displayNetworkDelayAlert:",
            name: "networkDelay", object: nil)
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "displayParseErrorAlert:",
            name: "parseError", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "displayNoGeopointsAlert:",
            name: "noGeopoints", object: nil)
        


        self.view.backgroundColor = .ITWelcomeColor()
    }
    
    func displayNoNetworkAlert(notification: NSNotification) {
        var alert = UIAlertController(title: "Unable to Connect",
            message: "Please check your internet connection.",
            preferredStyle: UIAlertControllerStyle.Alert)

        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))

        self.showViewController(alert, sender: nil)
    }
    
    func displayParseErrorAlert(notification: NSNotification) {
        var alert = UIAlertController(title: "Unable to Retrieve installations",
            message: "New nearby installations may not be detected.",
            preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Default, handler: nil))
        
        self.showViewController(alert, sender: nil)
    }
    
    func displayNoGeopointsAlert(notification: NSNotification) {
        var alert = UIAlertController(title: "Unable to find Instalation Locations",
            message: "Map may not indicate all nearby installations.",
            preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.showViewController(alert, sender: nil)
    }
    
    func displayNetworkDelayAlert(notification: NSNotification) {
        var alert = UIAlertController(title: "Delay in Finding Interactives",
            message: "The internet connection may not be sufficient for updating nearby interactives.",
            preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        
        self.showViewController(alert, sender: nil)
    }
    

    
    
    func refreshTable(notification: NSNotification) {
        
        appDelegate.dataManager.queryParseForInteractiveObjects()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    // MARK: TableView
    
    func makeInteractivesTableView() {
  

        if let interactivesNearbyTableView = interactivesNearbyTable {
            interactivesNearbyTableView.registerClass(UITableViewCell.classForCoder(), forCellReuseIdentifier: "identifier")
            interactivesNearbyTableView.registerNib(UINib(nibName: "InteractiveCard", bundle: nil), forCellReuseIdentifier: "identifier")
            
            interactivesNearbyTableView.dataSource = self
            interactivesNearbyTableView.delegate = self
            interactivesNearbyTableView.contentInset = UIEdgeInsetsMake(10,0,0,0)
            
            // Setup Refresh Control
            refreshControl = UIRefreshControl()
            refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh installations")
            refreshControl.addTarget(self, action: "handleRefresh:", forControlEvents: .ValueChanged)
            interactivesNearbyTableView.addSubview(refreshControl)
            
            
            interactivesNearbyTableView.rowHeight = 201
            view.addSubview(interactivesNearbyTableView)

        }
        
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nearbyInteractivesFriendlyArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        var cell: InteractiveCardCell! = tableView.dequeueReusableCellWithIdentifier("identifier") as? InteractiveCardCell

        
        var interactiveInfo = readyToDisplayInteractives[nearbyInteractivesFriendlyArray[indexPath.row]] as PFObject!
        var loc = interactiveInfo["location"] as PFGeoPoint
        var coordinate = CLLocationCoordinate2DMake(loc.latitude, loc.longitude)
        var lastSeen = getLastSeenTime(nearbyBLEInteractivesLastSeen[toString(interactiveInfo["name"])]!)
        
        cell.loadItem(title: nearbyInteractivesFriendlyArray[indexPath.row], desc: toString(interactiveInfo["explanation"]), lastSeen: lastSeen, coordinates: coordinate)
        // set up your background color view
        let colorView = UIView()
        colorView.backgroundColor = UIColor.clearColor()
        
        cell.selectedBackgroundView = colorView
        cell.backgroundColor = UIColor.clearColor()
//        cell.updateConstraints()
        
        return cell
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell,
        forRowAtIndexPath indexPath: NSIndexPath) {
            if didAnimateCell[indexPath] == nil || didAnimateCell[indexPath]! == false {
                didAnimateCell[indexPath] = true
                TipInCellAnimator.animate(cell)
            }
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let cell = tableView.cellForRowAtIndexPath(indexPath) as? InteractiveCardCell
        let interactiveName = cell?.interactiveName.text
        
        if interactiveName != nil {
            
            for (parseBLEName, parseFriendlyName) in appDelegate.dataManager.knownInteractivesFromParseFriendlyNames {
                if parseFriendlyName == interactiveName {
                    findBeanObjectAndConnectFromBLEName(parseBLEName)
                    showLoadingSpinner(parseFriendlyName)
                }
                
            }
        }
        
    }
    
    func showLoadingSpinner(interactiveName: String) {
        let loading = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        loading.labelText = "Contacting \(interactiveName)...";
    }
    
    func handleRefresh(paramSender: AnyObject) {
        
        appDelegate.dataManager.queryParseForInteractiveObjects()
        
        let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC))
        dispatch_after(popTime, dispatch_get_main_queue(), {
            self.refreshControl.endRefreshing()
        })
    }
    
    func getLastSeenTime(lastDiscoveredTime: NSDate) -> String {
        let dateFormatter = NSDateFormatter()
        let theTimeFormat = NSDateFormatterStyle.ShortStyle
        
        dateFormatter.timeStyle = theTimeFormat
        
        return dateFormatter.stringFromDate(lastDiscoveredTime)
    }
    
    // update table view after parse data is updated
    func updateTableView(notification: NSNotification){
        prepareInteractiveTableViewCellInformation()
    }
    
    // add new interactive to table view when notified
    func addNewInteractive(notification: NSNotification) {
        prepareInteractiveTableViewCellInformation()
    }
    
    func prepareInteractiveTableViewCellInformation() {
        
        for (nearbyName, bean) in nearbyBLEInteractives {
   
            for (parseBLEName, parseFriendlyName) in appDelegate.dataManager.knownInteractivesFromParseFriendlyNames {
    
                if contains(nearbyInteractivesFriendlyArray, parseFriendlyName) == false {
                    if nearbyName == parseBLEName {

                        self.getInteractiveObject(appDelegate.dataManager.knownInteractivesFromParse[parseBLEName]!)
                        nearbyBLEInteractivesLastSeen[parseFriendlyName] = bean.lastDiscovered
                        
                    }
                }
            }
        }
    }
    

    // get data from parse to insert into table view
    func getInteractiveObject(foundInteractiveObjectID: String){
        var query = PFQuery(className: "installations")
        query.fromLocalDatastore()
        query.getObjectInBackgroundWithId(foundInteractiveObjectID) {
            (objectInfo: PFObject!, error: NSError!) -> Void in
            if (error == nil) {
                // TO DO
                self.addToTableView(objectInfo)
            }
        }
    }
    
    func addToTableView(objectInfo: PFObject) {
        var objectName = objectInfo["name"] as String
        readyToDisplayInteractives[objectName] = objectInfo
        println("adding to table view")
        if contains(nearbyInteractivesFriendlyArray, objectName) == false {
            nearbyInteractivesFriendlyArray.append(objectName)
            interactivesNearbyTable.reloadData()
        }
        
    }
    
//    func deleteStaleCells() {
//        
//        tableView.begin
//        nearbyInteractivesFriendlyArray.removeAtIndex(indexPath.row)
//        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
//    }
    

    // MARK: PTDBeanManagerDelegate
    
    func beanManagerDidUpdateState(beanManager: PTDBeanManager!) {
        switch beanManager.state {
        case .PoweredOn:
            bluetoothIsReady = true
            NSNotificationCenter.defaultCenter().postNotificationName("readyToFind", object: nil)
        default:
            var bluetoothUnavailableAlert = UIAlertController(title: "Bluetooth Unavailable",
                message: "Bluetooth Low Energy is required to experience nearby installations.",
                preferredStyle: UIAlertControllerStyle.Alert)
            bluetoothUnavailableAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.showViewController(bluetoothUnavailableAlert, sender: nil)
            break
        }
    }
    
    func startScanningForInteractives(notif: NSNotification)
    {
        if appDelegate.dataManager.dataStoreReady == true && bluetoothIsReady == true {
            self.manager.startScanningForBeans_error(nil)
        }
    }
    
    func beanManager(beanManager: PTDBeanManager!, didDiscoverBean bean: PTDBean!, error: NSError!) {

        // add found interactive to dictionary
        if appDelegate.dataManager.isInteractiveKnown(toString(bean.name)) == true {
            nearbyBLEInteractives[bean.name] = bean
            NSNotificationCenter.defaultCenter().postNotificationName("AddedNewInteractive", object: nil)
        }
        
    }

    func BeanManager(beanManager: PTDBeanManager!, didConnectToBean bean: PTDBean!, error: NSError!) {
        println("CONNECTED BEAN \nName: \(bean.name), UUID: \(bean.identifier) RSSI: \(bean.RSSI)")
        
        if (error != nil){
            MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
            isConnecting = false
            
            var alert = UIAlertController(title: "Unable to Contact Interactive",
                message: "The experience isn't able to to start. Please try again later.",
                preferredStyle: UIAlertControllerStyle.Alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            
            self.showViewController(alert, sender: nil)
            return
        }
        
        if connectedBean == nil {
            connectedBeanObjectID = appDelegate.dataManager.knownInteractivesFromParse[bean.name]
            connectedBean = bean
            isConnecting = false
        }
    }
    
    func beanManager(beanManager: PTDBeanManager!, didDisconnectBean bean: PTDBean!, error: NSError!) {
        println("DISCONNECTED BEAN \nName: \(bean.name), UUID: \(bean.identifier) RSSI: \(bean.RSSI)")
        
        self.connectedBeanObjectID = nil
        self.connectedBean = nil
        isConnecting = false
        
        if (error != nil){
            var alert = UIAlertController(title: "Unable to Contact Interactive",
                message: "The experience isn't able to to start. Please try again later.",
                preferredStyle: UIAlertControllerStyle.Alert)
            
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Default, handler: nil))
            
            self.showViewController(alert, sender: nil)

           println("error disconnecting")
           println(error)
        } else {
            
            // Dismiss any modal view controllers.
            presentedViewController?.dismissViewControllerAnimated(true, completion: { () in
                self.dismissViewControllerAnimated(true, completion: nil)
            })
        }
        
         NSNotificationCenter.defaultCenter().postNotificationName("EndInteraction", object: nil)
        


    }
    
    // MARK: Bean Interaction Elements
    
    // end interaction by disconnecting and adding to temporary ignore list
    func clearCacheOfInteractives(notification: NSNotification) {
        println("clearing dictionary of known interactives")
        nearbyBLEInteractives.removeAll()
        nearbyInteractivesFriendlyArray.removeAll()
        
    }
    
    // end interaction by disconnecting and adding to temporary ignore list
    func endInteraction(notification: NSNotification) {
        println("end interaction notification in disconnected VC")
        // Dismiss any modal view controllers.
        presentedViewController?.dismissViewControllerAnimated(true, completion: { () in
            self.dismissViewControllerAnimated(true, completion: nil)
        })
        
        if connectedBean != nil {
            appDelegate.dataManager.previouslyExperiencedInteractivesToIgnore[toString(connectedBean!.name)] = connectedBean!.identifier!
            manager.disconnectBean(connectedBean, error:nil)
        }
    }
    
    // handles notification from beacon or settings page that a interaction is requested
    func initiateConnectionFromNotification(notification: NSNotification) {
        if let interactionInfo = notification.userInfo as? Dictionary<String, String>{
            if let id = interactionInfo["beaconInteractionBLEName"] {
                findBeanObjectAndConnectFromBLEName(id)
            }
        }
    }
    
    // initate request to connect
    func findBeanObjectAndConnectFromBLEName(bleName: String) {
        for (nearbyName, bean) in nearbyBLEInteractives {
            if bleName == nearbyName {
                intiateConnectionIfInteractionValid(bean)
            }
        }
    }
    
    // initate request to connect
    func findBeanObjectAndConnectFromFriendlyName(friendlyName: String) {
        for (parseBLEName, parseFriendlyName) in appDelegate.dataManager.knownInteractivesFromParseFriendlyNames {
            if parseFriendlyName == friendlyName {
                findBeanObjectAndConnectFromBLEName(parseBLEName)
            }
        }
    }
    
    // establish a connection after a final check that this is a valid bean
    func intiateConnectionIfInteractionValid(bean: PTDBean!) {
        
        // check if the interactive is in the parse data store
        if appDelegate.dataManager.isInteractiveKnown(toString(bean.name)) == true {
            
            // check if Bean SDK still has detected the bean
            if bean.state == .Discovered{
                println("Attempting to connect to \(toString(bean.name))")
                self.showLoadingSpinner("none")
                // prevent attempts to connect to other interactives
                if (isConnecting == false){
                    isConnecting = true
                    
//                    activityIndicator.startAnimating()
                    var connectError : NSError?
                    
                    manager.connectToBean(bean, error: &connectError)
                    
//                    // tell the user what we've found
//                    status.text = "Contacting \(appDelegate.dataManager.knownInteractivesFromParseFriendlyNames[bean.name]!)"
                }
            } else {
                println("ERROR: cant find that bean")
                
                var alert = UIAlertController(title: "Unable to Find Interactive",
                    message: "The experience isn't able to to start. Please try again later.",
                    preferredStyle: UIAlertControllerStyle.Alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                
                self.showViewController(alert, sender: nil)
            }
        }
    }

    // MARK: Location Notification
    
    // display aleart when user hasn't accepted location access or has turned it off
    func displayLocationAlert(notification: NSNotification?) {
        let alertController = UIAlertController(
            title: "Background Location Access Disabled",
            message: "In order to be notified about interactive experiences near you, please open this app's settings and set location access to 'Always'.",
            preferredStyle: .Alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let openAction = UIAlertAction(title: "Open Settings", style: .Default) { (action) in
            if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                UIApplication.sharedApplication().openURL(url)
            }
        }
        alertController.addAction(openAction)
        presentViewController(alertController, animated: true, completion: nil)
        
    }

    
}




