//
//  SettingsViewController.swift
//  
//
//  Created by Tom Arthur on 2/23/15.
//
//

import UIKit

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UINavigationBarDelegate {
    
    let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
    var nearbyBLEInteractives = [String:PTDBean]()
    var nearbyBLEInteractivesLastSeen = [String:NSDate]()
    var nearbyInteractivesFriendly = [String:PTDBean]()
    var nearbyInteractivesFriendlyArray = [String]()
    
    var refreshControl: UIRefreshControl?
    var tableCellsReady = false

    @IBOutlet weak var tabBar: UITabBar!
    
    //    var tableView: UITableView?
    var swipeRecognizer: UISwipeGestureRecognizer!
    
    @IBOutlet weak var settingsTable: UITableView!
    @IBOutlet var enabledSwitch: UISwitch!
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .TopAttached
    }
    
    func handleSwipes(sender: UISwipeGestureRecognizer){
        if sender.direction == .Right{
            self.dismissViewControllerAnimated(true, completion:nil)
        }
    }
    
    func closeSettings(sender: UIBarButtonItem){
        self.dismissViewControllerAnimated(true, completion:nil)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        // Assign tab bar item with titles
//        let tabBarController = UITabBarController()
//        tabBar.selectedItem = self.tabBar.items![2] as? UITabBarItem
        
        // when new interactive is discovered
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "addNewInteractive:",
            name: "AddedNewInteractive", object: nil)
        
        // when datastore and bluetooth are ready
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateTableView:",
            name: "readyToFind", object: nil)

        // Setup Table
        makeSettingsTableView()
        makeNavigationBar()
        setupSwipes()

        
        prepareInteractiveTableViewCellInformation()
    }

    func setupSwipes() {
        // Swipe to go back
        swipeRecognizer = UISwipeGestureRecognizer(target: self, action: "handleSwipes:")
        self.view.addGestureRecognizer(swipeRecognizer)
        swipeRecognizer.direction = .Right
        swipeRecognizer.numberOfTouchesRequired = 1
        
    }
    
    func makeSettingsTableView() {
        if let settingsTableView = settingsTable {
            settingsTableView.registerClass(UITableViewCell.classForCoder(), forCellReuseIdentifier: "identifier")
            
            settingsTableView.dataSource = self
            settingsTableView.delegate = self
            settingsTableView.contentInset = UIEdgeInsetsMake(64,0,0,0)
            
            // Setup Refresh Control
            refreshControl = UIRefreshControl()
            refreshControl!.addTarget(self, action: "handleRefresh:", forControlEvents: .ValueChanged)
            
            settingsTableView.addSubview(refreshControl!)
            view.addSubview(settingsTableView)
        }
        
    }
    
    func makeNavigationBar() {
        // Create the navigation bar
        let navigationBar = UINavigationBar(frame: CGRectMake(0, 20, UIScreen.mainScreen().bounds.width, 44)) // Offset by 20 pixels vertically to take the status bar into account
        var backgroundColor: UIColor
        navigationBar.barTintColor = .ITWelcomeColor()
        navigationBar.translucent = true
        navigationBar.delegate = self
        
        let navigationItem = UINavigationItem()
        navigationItem.title = "Manual Control"
        navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        
        let backButton = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.Plain, target: self, action: "closeSettings:")
        backButton.tintColor = UIColor.whiteColor()
        //        backButton.tit = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        navigationItem.leftBarButtonItem = backButton
        
        navigationBar.items = [navigationItem]
        self.view.addSubview(navigationBar)

        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section{
            case 0:
                return 1
            case 1:
                return nearbyInteractivesFriendlyArray.count
            default:
                return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("identifier", forIndexPath: indexPath) as UITableViewCell
//        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Identifier")
        
        if (indexPath.section == 0) {
            cell.textLabel?.text = "Null"
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            
        } else if (indexPath.section == 1){
            cell.textLabel?.text = nearbyInteractivesFriendlyArray[indexPath.row]
            let lastSeenTime = getLastSeenTime(nearbyBLEInteractivesLastSeen[nearbyInteractivesFriendlyArray[indexPath.row]]!)
            cell.detailTextLabel?.text = "Last discovered at \(lastSeenTime)"
        }
        
        return cell
    }


    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.section == 1 {
            let cell = tableView.cellForRowAtIndexPath(indexPath)
            let text = cell?.textLabel?.text
            
            if text != nil {
                requestInteractiveConnectionAndCloseView(text!)
            }
            
        }

    
    }

    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 30
    }
    
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView{
        
        switch section{
            case 0:
                return newViewForHeaderWithText("Experience")
            case 1:
                return newViewForHeaderWithText("Nearby")
            default:
                return newViewForHeaderWithText("Oops...")
        }

    }
    
    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView{
        switch section{
            case 0:
                return newViewForFooterWithText("Null.")
            case 1:
                return newViewForFooterWithText("Interactive objects discovered around you.\nTap to contact.")
            default:
                return newViewForFooterWithText("Oops...")
        }
    }
    
    func newHeaderLabelWithTitle(title: String) -> UILabel{
        let label = UILabel()
        label.text = title
        label.backgroundColor = UIColor.clearColor()
        label.numberOfLines = 0
        label.sizeToFit()
        return label
    }
    
    func newFooterLabelWithTitle(title: String) -> UILabel{
        let label = UILabel()
        label.text = title
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.ByWordWrapping
        label.font =  UIFont (name: "HelveticaNeue-Light", size: 12)
        label.backgroundColor = UIColor.clearColor()
        label.sizeToFit()
        return label
    }
    
    func newViewForHeaderWithText(text: String) -> UIView{
        let headerLabel = newHeaderLabelWithTitle(text)
        
        /* let's make this look correct */
        headerLabel.frame.origin.x += 10
        headerLabel.frame.origin.y = 5
        
        let resultFrame = CGRect(x: 0, y: 0,
            width: headerLabel.frame.size.width + 10,
            height: headerLabel.frame.size.height)
        
        let headerView = UIView(frame: resultFrame)
        headerView.addSubview(headerLabel)
        
        return headerView
    }
    
    func newViewForFooterWithText(text: String) -> UIView{
        let footerLabel = newFooterLabelWithTitle(text)
        
        /* let's make this look correct */
        footerLabel.frame.origin.x += 10
        footerLabel.frame.origin.y = 5
        
        let resultFrame = CGRect(x: 0, y: 0,
            width: footerLabel.frame.size.width + 10,
            height: footerLabel.frame.size.height)
        
        let footerView = UIView(frame: resultFrame)
        footerView.addSubview(footerLabel)
        
        return footerView
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
                if nearbyName == parseBLEName {
                    nearbyInteractivesFriendly[parseFriendlyName] = bean
                    nearbyBLEInteractivesLastSeen[parseFriendlyName] = bean.lastDiscovered
                    if contains(nearbyInteractivesFriendlyArray, parseFriendlyName) == false {
                        nearbyInteractivesFriendlyArray.append(parseFriendlyName)
                    }
                }
            }
        }
        tableCellsReady = true

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
        settingsTable.reloadData()
    }
    
    // update table view after parse data is updated
    func updateTableView(notification: NSNotification){
        prepareInteractiveTableViewCellInformation()
        settingsTable.reloadData()
    }
    
    
}
