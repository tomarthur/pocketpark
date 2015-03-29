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


class DisconnectedViewController: UIViewController, UINavigationBarDelegate, UITableViewDataSource, UITableViewDelegate, PTDBeanManagerDelegate {
    
    let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var interactivesNearbyTable: UITableView!
    var refreshControl:UIRefreshControl!
    var didAnimateCell:[NSIndexPath: Bool] = [:]
    var nearbyInteractivesFriendlyArray = [String]()        // Table view content
    var readyToDisplayInteractives = [String:PFObject]()    // Table view content
    
    var bluetoothIsReady = false
    var statusShown = true
    
    var connectedBeanObjectID: String?                      // Parse objectId for connected bean
    var nearbyBLEInteractives = [String:PTDBean]()          // PTDBean objects detected in the area
    var connectionRequestTimer = NSTimer()
    
    let refreshTime = 30.0
    let delayRemoveAfterRefresh = 2.0
    var refreshBLEObjects = NSTimer()
    var refreshTimerActive = false

    var manager: PTDBeanManager!
    var connectedBean: PTDBean? {
        didSet {
            if connectedBean == nil {
                self.beanManagerDidUpdateState(manager)

            } else {
                self.connectionRequestTimer.invalidate()
                
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
    
    func startRefreshTimer () {
        if (refreshTimerActive == false) {
            refreshTimerActive = true
            refreshBLEObjects = NSTimer.scheduledTimerWithTimeInterval(refreshTime, target: self, selector: Selector("stopStartScan"), userInfo: nil, repeats: true)
        } else {
            println("already started timer")
        }
    }
    
    func invalidatRefreshTimer () {
        refreshBLEObjects.invalidate()
        refreshTimerActive = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        showStatus("Preparing to discover installations nearby.")

        appDelegate.dataManager.checkNetwork()
        
        startRefreshTimer()
        
        manager = PTDBeanManager(delegate: self)
        
        makeInteractivesTableView()
        
        // Notifications

        // when datastore and bluetooth are ready start scanning
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "startScanningForInteractives:",
            name: "readyToFind", object: nil)
        
        // when new interactive is discovered add to table view
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "addNewInteractive:",
            name: "AddNewInteractive", object: nil)
        
        // when iBeacon of interactive is detected
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "initiateConnectionFromNotification:",
            name: "startInteractionFromNotification", object: nil)
        
        // when iBeacon of interactive is detected
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "initiateConnectionFromTap:",
            name: "StartInteractionFromTap", object: nil)
        
        // get notification when user wants to end experience
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "endInteraction:",
            name: "EndInteraction", object: nil)
        
        // when app is no longer in focus, disconnect
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "endInteraction:",
            name: UIApplicationDidEnterBackgroundNotification, object: nil)
        
        // when app is no longer in focus, clear cache of found items
         NSNotificationCenter.defaultCenter().addObserver(self, selector: "pauseTimer:",
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
    
    override func viewDidAppear(animated: Bool) {
        makeNavigationBar()
    }
    
    func makeNavigationBar () {
        
        // Create the navigation bar
        let navigationBar = UINavigationBar(frame: CGRectMake(0, 20, self.view.frame.size.width, 44)) // Offset by 20 pixels vertically to take the status bar into account
        navigationBar.barStyle = .Black
        navigationBar.delegate = self;
        
        // Create a navigation item with a title
        let navigationItem = UINavigationItem()
        navigationItem.title = "Theme Park of Everyday"
        navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont(name: "OtterFont", size: 25)!]
        
        navigationBar.items = [navigationItem]
        
        // Make the navigation bar a subview of the current view controller
        self.view.addSubview(navigationBar)
    }
    
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .TopAttached
    }
    
    func displayNoNetworkAlert(notification: NSNotification) {
        println("SHOULD REPORT NETWORK PROBLEM")
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
        
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        
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

    func showStatus(currentStatus: String) {
        
        activityIndicator.startAnimating()
        statusLabel.text = currentStatus
        statusLabel.fadeIn()
    }
    
    func hideStatus() {
        activityIndicator.stopAnimating()
        statusLabel.fadeOut()
    }
    
    func showLoadingSpinner(interactiveName: String) {
        MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
        let loading = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        loading.labelText = "Contacting \(interactiveName)";
    }
    
    func showContactingSpinner(interactiveName: String) {
        MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
        let loading = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        loading.labelText = "Discovering \(interactiveName)";
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
            interactivesNearbyTableView.contentInset = UIEdgeInsetsMake(67,0,0,0)
            
            // Setup Refresh Control
            refreshControl = UIRefreshControl()
            refreshControl.addTarget(self, action: "handleRefresh:", forControlEvents: .ValueChanged)
            interactivesNearbyTableView.addSubview(refreshControl)
            
            interactivesNearbyTableView.rowHeight = 201
            view.addSubview(interactivesNearbyTableView)

        }
        
    }

    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 50
    }

    func tableView(tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        view.tintColor = .clearColor()
        view.backgroundColor = .clearColor()
//        contentView.backgroundColor.clea
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nearbyInteractivesFriendlyArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        var cell: InteractiveCardCell! = tableView.dequeueReusableCellWithIdentifier("identifier") as? InteractiveCardCell

        // make cell background clear
        let colorView = UIView()
        colorView.backgroundColor = UIColor.clearColor()
        
        cell.selectedBackgroundView = colorView
        cell.selectionStyle = .None
        cell.backgroundColor = UIColor.clearColor()
        
        // load content to cell
        
        var interactiveInfo = readyToDisplayInteractives[nearbyInteractivesFriendlyArray[indexPath.row]] as PFObject!
        var loc = interactiveInfo["location"] as PFGeoPoint
        var coordinate = CLLocationCoordinate2DMake(loc.latitude, loc.longitude)
        
        cell.loadItem(title: nearbyInteractivesFriendlyArray[indexPath.row], desc: toString(interactiveInfo["explanation"]), coordinates: coordinate)

        return cell
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell,
        forRowAtIndexPath indexPath: NSIndexPath) {
            if didAnimateCell[indexPath] == nil || didAnimateCell[indexPath]! == false {
                didAnimateCell[indexPath] = true
                TipInCellAnimator.animate(cell)
            }
    }


    
    func handleRefresh(paramSender: AnyObject) {
        
        appDelegate.dataManager.queryParseForInteractiveObjects()
        
        let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC))
        dispatch_after(popTime, dispatch_get_main_queue(), {
            self.refreshControl.endRefreshing()
        })
    }
    
    // add new interactive to table view when notified
    func addNewInteractive(notification: NSNotification) {
        if let notificationInfo = notification.userInfo as? Dictionary<String, PTDBean>{
            
            if let id = notificationInfo["NewBean"] {
                prepareInteractiveTableViewCellInformation(id)
            }
        }
    }
    
    func refreshTable(notification: NSNotification) {
        startRefreshTimer()
        stopStartScan()
    }
    
    func prepareInteractiveTableViewCellInformation (bean:PTDBean) {
        hideStatus()
        if let parseFriendlyName = appDelegate.dataManager.knownInteractivesFromParseFriendlyNames [bean.name] {

            if contains(nearbyInteractivesFriendlyArray, parseFriendlyName) == false {
                let objectID = appDelegate.dataManager.knownInteractivesFromParse[bean.name]
                println("objectID: \(objectID)")
                getInteractiveObject(objectID!)
            } else {
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
        if contains(nearbyInteractivesFriendlyArray, objectName) == false {
            nearbyInteractivesFriendlyArray.append(objectName)
            interactivesNearbyTable.beginUpdates()
            let lastIndexPath = NSIndexPath(forRow: nearbyInteractivesFriendlyArray.count - 1, inSection: 0)
            interactivesNearbyTable.insertRowsAtIndexPaths([lastIndexPath], withRowAnimation: .None)
            interactivesNearbyTable.endUpdates()
        }
        
    }
    
    func deleteRowsAtIndexPaths(indexPaths: [AnyObject],
        withRowAnimation animation: UITableViewRowAnimation) {
            
    }
    
    func removeStaleData()
    {
        interactivesNearbyTable.beginUpdates()
        var rowsToDelete = [NSIndexPath]()
        var removedItems = 0
        for (index,friendlyName) in enumerate(nearbyInteractivesFriendlyArray)
        {
            var BLEName = getBLEName(friendlyName)
            if !BLEName.isEmpty
            {
                let found = nearbyBLEInteractives[BLEName] != nil
                
                if found == false
                {
                    readyToDisplayInteractives[friendlyName] = nil
                    rowsToDelete.append(NSIndexPath(forRow: index, inSection: 0))
                    didAnimateCell[rowsToDelete.last!] = false
                    nearbyInteractivesFriendlyArray.removeAtIndex(index - removedItems)
                    removedItems++
                }
            }
        }
        
        if rowsToDelete.count > 0 {
            interactivesNearbyTable.deleteRowsAtIndexPaths(rowsToDelete, withRowAnimation: UITableViewRowAnimation.Fade)
            rowsToDelete.removeAll()
        }
        
        if nearbyBLEInteractives.count == 0 {
            showStatus("Nearby installations appear automatically when discovered.\nCheck out the map for all locations.")
        }
        interactivesNearbyTable.endUpdates()
    }

    
    

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
        if appDelegate.dataManager.dataStoreReady == true && bluetoothIsReady == true && runningInForground() == true {
            if nearbyBLEInteractives.count == 0 {
            showStatus("Nearby installations appear automatically when discovered.\nCheck out the map for all locations.")
            }
            self.manager.startScanningForBeans_error(nil)
        }
    }
    
    func runningInForground() -> Bool {
        var state = UIApplication.sharedApplication().applicationState
        
        if (state == .Active) {
            println("SCAN!!!!!")
            return true
        } else {
            println("NO SCAN IN BACKROUND")
            return false
        }
        
    }
    
    func stopStartScan()
    {
        if appDelegate.dataManager.dataStoreReady == false || bluetoothIsReady == false || runningInForground() == false {
            println("no scan becuase things aren't ready")
            return
        }
        
//        self.manager.stopScanningForBeans_error(nil)
        clearCacheOfInteractives()
        self.manager.startScanningForBeans_error(nil)
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delayRemoveAfterRefresh * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
            self.removeStaleData()
        })
  
    }
    
    
    func getBLEName(FriendlyName:String) -> String
    {
        var keysArr = appDelegate.dataManager.knownInteractivesFromParseFriendlyNames.keys.array
        for key in keysArr
        {
            if appDelegate.dataManager.knownInteractivesFromParseFriendlyNames[key]==FriendlyName
            {
                return key
            }
        }
        return ""
    }
    
    func beanManager(beanManager: PTDBeanManager!, didDiscoverBean bean: PTDBean!, error: NSError!) {
        
        // add found interactive to dictionary
        if appDelegate.dataManager.isInteractiveKnown(toString(bean.name)) == true {
            nearbyBLEInteractives[bean.name] = bean
            var requestNotificationDict: [String:PTDBean] = ["NewBean" : bean!]
            NSNotificationCenter.defaultCenter().postNotificationName("AddNewInteractive", object: nil, userInfo: requestNotificationDict)
        }
        
    }

    func BeanManager(beanManager: PTDBeanManager!, didConnectToBean bean: PTDBean!, error: NSError!) {
        println("CONNECTED BEAN \nName: \(bean.name), UUID: \(bean.identifier) RSSI: \(bean.RSSI)")
        
        if (error != nil){
            connectionFailure()
            return
        }
        
        if connectedBean == nil {
            connectedBeanObjectID = appDelegate.dataManager.knownInteractivesFromParse[bean.name]
            connectedBean = bean
        }
    }
    
    func beanManager(beanManager: PTDBeanManager!, didDisconnectBean bean: PTDBean!, error: NSError!) {
        println("DISCONNECTED BEAN \nName: \(bean.name), UUID: \(bean.identifier) RSSI: \(bean.RSSI)")
        
        self.connectedBeanObjectID = nil
        self.connectedBean = nil
        
        // Dismiss any modal view controllers.
        presentedViewController?.dismissViewControllerAnimated(true, completion: { () in
            self.dismissViewControllerAnimated(true, completion: nil)
        })
        
        if (error != nil){
            println("error \(error)")
        }
        
         NSNotificationCenter.defaultCenter().postNotificationName("EndInteraction", object: nil)

    }
    
    // MARK: Bean Interaction Elements
    
    // end interaction by disconnecting and adding to temporary ignore list
    func clearCacheOfInteractives() {
        
//        println("clearing dictionary of known interactives")
        nearbyBLEInteractives.removeAll()
 
        
    }
    
    func pauseTimer(notification: NSNotification) {
        println("timer stopped")
        invalidatRefreshTimer()
        manager.stopScanningForBeans_error(nil)

    }
    
    // end interaction by disconnecting and adding to temporary ignore list
    func endInteraction(notification: NSNotification) {
        // Dismiss any modal view controllers.
        presentedViewController?.dismissViewControllerAnimated(true, completion: { () in
            self.dismissViewControllerAnimated(true, completion: nil)
        })
        
        if connectedBean != nil {
            appDelegate.dataManager.previouslyExperiencedInteractivesToIgnore[toString(connectedBean!.name)] = connectedBean!.identifier!
            manager.disconnectFromAllBeans(nil)
        }
    }
    

    func initiateConnectionFromTap(notification: NSNotification) {
        if let interactionInfo = notification.userInfo as? Dictionary<String, String>{

            if let id = interactionInfo["beaconInteractionBLEName"] {

                for (parseBLEName, parseFriendlyName) in appDelegate.dataManager.knownInteractivesFromParseFriendlyNames {
                    
                    if parseBLEName == id {

                        for (nearbyName, bean) in nearbyBLEInteractives {
                            
                            if id == nearbyName {
                                self.intiateConnectionIfInteractionValid(bean, friendlyName: parseFriendlyName)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func initiateConnectionFromNotification(notification: NSNotification) {
        if let interactionInfo = notification.userInfo as? Dictionary<String, String>{
            
            if let id = interactionInfo["beaconInteractionBLEName"] {
                
                for (parseBLEName, parseFriendlyName) in appDelegate.dataManager.knownInteractivesFromParseFriendlyNames {
                    
                    if parseBLEName == id {
                        showContactingSpinner(parseFriendlyName)
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delayRemoveAfterRefresh * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
                            self.completeConnectionFromNotificationAfterDelay(parseBLEName, friendlyNameIn: parseFriendlyName)
                        })
                    } else {
                        println("Didn't work")
                    }
                }
            }
        }
    }
    
    func completeConnectionFromNotificationAfterDelay(bleName: String, friendlyNameIn: String) {
        for (nearbyName, bean) in nearbyBLEInteractives {
            if bleName == nearbyName {
                self.intiateConnectionIfInteractionValid(bean, friendlyName: friendlyNameIn)
            }
        }
    }
    

    // establish a connection after a final check that this is a valid bean
    func intiateConnectionIfInteractionValid(bean: PTDBean!, friendlyName: String) {
        
        // check if Bean SDK still has detected the bean
        if bean.state == .Discovered{

            self.showLoadingSpinner(friendlyName)
            
            var connectError : NSError?
            manager.connectToBean(bean, error: &connectError)
            
            connectionRequestTimer = NSTimer.scheduledTimerWithTimeInterval(10.0, target: self, selector: Selector("connectionFailure"), userInfo: nil, repeats: false)
            
        } else {
            connectionFailure()
        }

    }
    
    func connectionFailure() {
        // Send the dimensions to Parse along with the 'connect' event
        let connectInfo = [
            // Define ranges to bucket data points into meaningful segments
            "interactiveName": toString(connectedBean?.name),
            // Did the user filter the query?
            "connectFailure": toString(NSDate())
        ]
        PFAnalytics.trackEvent("connectFailure", dimensions:connectInfo)
        
        var disconnectError : NSError?
        manager.disconnectFromAllBeans(&disconnectError)

        self.connectedBeanObjectID = nil
        self.connectedBean = nil
        
        MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
        
        var alert = UIAlertController(title: "Unable to Contact Interactive",
            message: "The experience isn't able to to start. Please try again later.",
            preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.showViewController(alert, sender: nil)
        

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




