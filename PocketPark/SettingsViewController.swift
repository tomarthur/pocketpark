//
//  SettingsViewController.swift
//  
//
//  Created by Tom Arthur on 2/23/15.
//
//

import UIKit

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
    var nearbyBLEInteractives = [String:PTDBean]()
    var nearbyBLEInteractivesLastSeen = [String:NSDate]()
    var nearbyInteractivesFriendly = [String:PTDBean]()
    var nearbyInteractivesFriendlyArray = [String]()
    var readyToDisplayInteractives = [String:PFObject]()
    
    var refreshControl: UIRefreshControl?
    var tableCellsReady = false

    @IBOutlet weak var settingsTable: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // build the dictionary of geopoints
        appDelegate.dataManager.dictionaryOfInteractivesWithGeoPoints()
        
        
        // when new interactive is discovered
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "addNewInteractive:",
            name: "AddedNewInteractive", object: nil)
        
        // when datastore and bluetooth are ready
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateTableView:",
            name: "readyToFind", object: nil)

        // Setup Table
        makeSettingsTableView()

        
        prepareInteractiveTableViewCellInformation()
        
        self.view.backgroundColor = .ITWelcomeColor()
    }

    
    func makeSettingsTableView() {
        if let settingsTableView = settingsTable {
            settingsTableView.registerClass(UITableViewCell.classForCoder(), forCellReuseIdentifier: "identifier")
            
            settingsTableView.dataSource = self
            settingsTableView.delegate = self
            settingsTableView.contentInset = UIEdgeInsetsMake(0,0,0,0)
            
            // Setup Refresh Control
            refreshControl = UIRefreshControl()
            refreshControl!.addTarget(self, action: "handleRefresh:", forControlEvents: .ValueChanged)
            
            settingsTableView.rowHeight = UITableViewAutomaticDimension
            
            settingsTableView.addSubview(refreshControl!)
            view.addSubview(settingsTableView)
        }
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nearbyInteractivesFriendlyArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let identifier = "Cell"
        var cell: InteractiveCardCell! = tableView.dequeueReusableCellWithIdentifier("identifier") as? InteractiveCardCell
        if cell == nil {
            tableView.registerNib(UINib(nibName: "InteractiveCard", bundle: nil), forCellReuseIdentifier: "identifier")
        }
        
        cell = tableView.dequeueReusableCellWithIdentifier("identifier") as? InteractiveCardCell
        
        var interactiveInfo = readyToDisplayInteractives[nearbyInteractivesFriendlyArray[indexPath.row]] as PFObject!
        var loc = interactiveInfo["location"] as PFGeoPoint
        var coordinate = CLLocationCoordinate2DMake(loc.latitude, loc.longitude)
        cell.loadItem(title: nearbyInteractivesFriendlyArray[indexPath.row], desc: toString(interactiveInfo["explanation"]), coordinates: coordinate)
        cell.updateConstraints()
        
        return cell
        

    }


    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
//            let cell = tableView.dequeueReusableCellWithIdentifier("identifier") as? InteractiveCardCell
            let cell = tableView.cellForRowAtIndexPath(indexPath) as? InteractiveCardCell
            let interactiveName = cell?.interactiveName.text
        
            if interactiveName != nil {
                requestInteractiveConnectionAndCloseView(interactiveName!)
            }
            
        }


    
    func handleRefresh(paramSender: AnyObject) {
        
        appDelegate.dataManager.queryParseForInteractiveObjects()
        
        let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC))
        dispatch_after(popTime, dispatch_get_main_queue(), {
            self.refreshControl!.endRefreshing()
        })
    }

    

    func requestInteractiveConnectionAndCloseView(nameOfInteractive: String){
        println("trying to send connect request for \(nameOfInteractive)")
        let interactiveDesired = nearbyInteractivesFriendly[nameOfInteractive]
        
        self.dismissViewControllerAnimated(true, completion:nil)
        
        var requestNotificationDict: [String:PTDBean!] = ["beaconInteractionObject" : interactiveDesired]
        NSNotificationCenter.defaultCenter().postNotificationName("startInteractionRequest", object: self, userInfo: requestNotificationDict)
    }
    
    func prepareInteractiveTableViewCellInformation() {
        println("making table cell info ready")
        tableCellsReady = false

        for (nearbyName, bean) in nearbyBLEInteractives {
                for (parseBLEName, parseFriendlyName) in appDelegate.dataManager.knownInteractivesFromParseFriendlyNames {
                    
                    if contains(nearbyInteractivesFriendlyArray, parseFriendlyName) == false {
                        if nearbyName == parseBLEName {
                            println("adding \(parseFriendlyName)")
                            self.getInteractiveObject(appDelegate.dataManager.knownInteractivesFromParse[parseBLEName]!)
                            nearbyInteractivesFriendly[parseFriendlyName] = bean
                            nearbyBLEInteractivesLastSeen[parseFriendlyName] = bean.lastDiscovered

                        }
                    }
                }
        }
    }
    
    func addToTableView(objectInfo: PFObject) {
        var objectName = objectInfo["name"] as String
        readyToDisplayInteractives[objectName] = objectInfo
        
        if contains(nearbyInteractivesFriendlyArray, objectName) == false {
            nearbyInteractivesFriendlyArray.append(objectName)
            settingsTable.reloadData()
        }

    }
    
    func getLastSeenTime(lastDiscoveredTime: NSDate) -> String {
        let dateFormatter = NSDateFormatter()
        let theTimeFormat = NSDateFormatterStyle.ShortStyle
        
        dateFormatter.timeStyle = theTimeFormat
        
        return dateFormatter.stringFromDate(lastDiscoveredTime)
    }
    
    // add new interactive when notified
    func addNewInteractive(notification: NSNotification) {
        println("notified of new interactive")
        if let beanDictionary = notification.userInfo as? Dictionary<String, PTDBean>{

                nearbyBLEInteractives = beanDictionary
        }
        prepareInteractiveTableViewCellInformation()
    }
    
    // update table view after parse data is updated
    func updateTableView(notification: NSNotification){
        prepareInteractiveTableViewCellInformation()
    }
    
    func getInteractiveObject(foundInteractiveObjectID: String){
        var query = PFQuery(className: "installations")
        query.fromLocalDatastore()
        query.getObjectInBackgroundWithId(foundInteractiveObjectID) {
            (objectInfo: PFObject!, error: NSError!) -> Void in
            if (error == nil) {
                // TO DO
                self.addToTableView(objectInfo)
            } else {
                // There was an error.
                UIAlertView(
                    title: "Error",
                    message: "Unable to retrieve interactive.",
                    delegate: self,
                    cancelButtonTitle: "OK"
                    ).show()
                NSLog("Unable to find interactive in local data store")
                NSLog("Error: %@ %@", error, error.userInfo!)
            }
        }
    }
    
}
