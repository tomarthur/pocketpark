//
//  SettingsViewController.swift
//  
//
//  Created by Tom Arthur on 2/23/15.
//
//

import UIKit

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UINavigationBarDelegate {
    
    var nearbyBLEInteractives = [NSUUID:String]()
    
    @IBOutlet weak var settingsTable: UITableView!
//    let disconnectedViewController = UIApplication.sharedApplication(). as AppDelegate
//    let disconnectedViewController = deleg
////    delegate
    
    var allTimes = [NSDate]()
    var refreshControl: UIRefreshControl?
    
    var tableView: UITableView?
    var swipeRecognizer: UISwipeGestureRecognizer!
    
    func handleSwipes(sender: UISwipeGestureRecognizer){
        if sender.direction == .Right{
            self.dismissViewControllerAnimated(true, completion:nil)
        }
    }
    
    func closeSettings(){
        self.dismissViewControllerAnimated(true, completion:nil)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .TopAttached
    }

    override func viewDidLoad() {
        println("Howdy from Settings View")
        super.viewDidLoad()
        
        println(nearbyBLEInteractives.count)
        for (key, value) in nearbyBLEInteractives {
            println("\(key) -> \(value)")
        }

        allTimes.append(NSDate())
        
        // Setup Table
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
        

        
        // Create the navigation bar
        let navigationBar = UINavigationBar(frame: CGRectMake(0, 20, UIScreen.mainScreen().bounds.width, 44)) // Offset by 20 pixels vertically to take the status bar into account
        var backgroundColor: UIColor
        navigationBar.barTintColor = .ITWelcomeColor()
        navigationBar.translucent = true
        navigationBar.delegate = self
        
        let navigationItem = UINavigationItem()
        navigationItem.title = "Settings"
        navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        
        let backButton = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.Plain, target: self, action: "closeSettings:")
        navigationItem.leftBarButtonItem = backButton
        
        navigationBar.items = [navigationItem]
        self.view.addSubview(navigationBar)
        
        // Swipe to go back
        swipeRecognizer = UISwipeGestureRecognizer(target: self, action: "handleSwipes:")
        self.view.addGestureRecognizer(swipeRecognizer)
        swipeRecognizer.direction = .Right
        swipeRecognizer.numberOfTouchesRequired = 1
        
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section{
            case 0:
                return 1
            case 1:
                return 5
            default:
                return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("identifier", forIndexPath: indexPath) as UITableViewCell
        
        cell.textLabel?.text = "hello"
        
        return cell
    }
    
    func newLabelWithTitle(title: String) -> UILabel{
        let label = UILabel()
        label.text = title
        label.backgroundColor = UIColor.clearColor()
        label.sizeToFit()
        return label
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView{
        
        switch section{
            case 0:
                return newViewForHeaderOrFooterWithText("Experience Settings")
            case 1:
                return newViewForHeaderOrFooterWithText("Discovered Experiences")
            default:
                return newViewForHeaderOrFooterWithText("Oops...")
        }

    }
    
//    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView{
//        switch section{
//            case 0:
//                return newViewForHeaderOrFooterWithText("Experience Settings")
//            case 1:
//                return newViewForHeaderOrFooterWithText("Discovered Experiences")
//            default:
//                return newViewForHeaderOrFooterWithText("Oops...")
//        }
//    }
    
    func newViewForHeaderOrFooterWithText(text: String) -> UIView{
        let headerLabel = newLabelWithTitle(text)
        
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
    
    func handleRefresh(paramSender: AnyObject) {
        
        let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC))
        dispatch_after(popTime, dispatch_get_main_queue(), {
            self.allTimes.append(NSDate())
            self.refreshControl!.endRefreshing()
//            let indexPathOfNewRow = NSIndexPath(forRow: self.allTimes.count - 1, inSection: 1)
//            self.settingsTable.insertRowsAtIndexPaths([indexPathOfNewRow], withRowAnimation: .Automatic)
        
        })
    }
//    func addSettingsToTableView {
//        
//    }
//    
//    @IBAction func pressedDone(sender: AnyObject) {
//        
//    }
    
    
}
