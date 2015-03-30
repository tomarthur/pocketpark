//
//  AppDelegate.swift
//  interactron
//
//  Created by Tom Arthur on 2/16/15.
//  Copyright (c) 2015 Tom Arthur. All rights reserved.
//

import UIKit




@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    
    var interactionBeaconManager = InteractionBeaconManager()   // Core Location
    var dataManager = DataManager()                             // Parse Data
    var pushNotificationController:PushNotificationController?  // Push Notifications

    let defaults = NSUserDefaults.standardUserDefaults()
    let userHasOnboardedKey = "user_has_onboarded"
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Parse framework for analytics, data and bug tracking
        ParseCrashReporting.enable()
        Parse.enableLocalDatastore()
        Parse.setApplicationId("yc2HKK3EGe1tDIlvTyY9x2dKhgGaVNai7dQWfvGG",
                clientKey: "dVeENxp57pgP3Zwqlez4U2G8O64B1tXQUBKsgTC1")
        PFAnalytics.trackAppOpenedWithLaunchOptions(launchOptions)
        
        PFUser.enableAutomaticUser()
        PFUser.currentUser().incrementKey("RunCount")
        PFUser.currentUser().saveInBackground()
        
        // start Parse datamanager
        dataManager.start()
        
        // activate CL manager
        interactionBeaconManager.start()
        
        // stop location when app is open
        interactionBeaconManager.locationManager?.stopUpdatingLocation()
        
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window!.backgroundColor = .ITWelcomeColor()
        
        // Determine if the user has completed onboarding yet or not
        var userHasOnboardedAlready = NSUserDefaults.standardUserDefaults().boolForKey(userHasOnboardedKey);
        
        // If the user has already onboarded, setup the normal root view controller for the application
        // without animation like you normally would if you weren't doing any onboarding
        if userHasOnboardedAlready {
            self.setupNormalRootVC(false);
        }
            // Otherwise the user hasn't onboarded yet, so set the root view controller for the application to the
            // onboarding view controller generated and returned by this method.
        else {
            self.window!.rootViewController = self.generateOnboardingViewController()
        }
        
        self.window!.makeKeyAndVisible()

        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        interactionBeaconManager.startMonitoringForRegionOnly()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

        interactionBeaconManager.stopUpdatingLocation()
        
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        interactionBeaconManager.startMonitoringForRegionOnly()
    }
    
    func askForNotificationPermissionForApplication(){
        // Local Notification Registration
        
        self.pushNotificationController = PushNotificationController()
        
        if(UIApplication.sharedApplication().respondsToSelector("registerUserNotificationSettings:")) {
            UIApplication.sharedApplication().registerUserNotificationSettings(
                UIUserNotificationSettings(
                    forTypes: UIUserNotificationType.Alert | UIUserNotificationType.Sound | UIUserNotificationType.Badge,
                    categories: nil
                )
            )
            UIApplication.sharedApplication().registerForRemoteNotifications()
        }
        
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        println("didRegisterForRemoteNotificationsWithDeviceToken")
        
        let currentInstallation = PFInstallation.currentInstallation()
        
        currentInstallation.setDeviceTokenFromData(deviceToken)
        currentInstallation.saveInBackgroundWithBlock { (succeeded, e) -> Void in
            //code
        }
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        println("failed to register for remote notifications:  (error)")
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        println("didReceiveRemoteNotification")
        PFPush.handlePush(userInfo)
    }
    
    func application(application: UIApplication,
        didReceiveLocalNotification notification: UILocalNotification) {
            

            let friendlyName = notification.userInfo!["friendlyName"] as? String
            let bleName = notification.userInfo!["bleName"] as? String

            if friendlyName != nil && bleName != nil{
                
                if let tabBarController = self.window!.rootViewController as? UITabBarController {
                    tabBarController.selectedIndex = 1
                }
                
                var requestNotificationDict: [String:String] = ["beaconInteractionBLEName" : bleName!]
                NSNotificationCenter.defaultCenter().postNotificationName("startInteractionFromNotification", object: self, userInfo: requestNotificationDict)
            } else {
                /* This is not the notification that we composed */
            }
            
    }
    
    func generateOnboardingViewController() -> OnboardingViewController {
        // generate the welcome page
        let welcomePage: OnboardingContentViewController = OnboardingContentViewController(title: "Control the World", body: "PocketPark is your gateway to  experiences embedded in the world around you.", image: UIImage(named:
            "blue"), buttonText: nil) {
        }

        // Generate the first page...
        let firstPage: OnboardingContentViewController = OnboardingContentViewController(title: "Discover Installations Around You", body: "Enableing location services will help you find nearby installations.", image: UIImage(named:
            "blue"), buttonText: nil) {
                
        }
        
        // Generate the second page...
        let secondPage: OnboardingContentViewController = OnboardingContentViewController(title: "Get Notified", body: "When you're near an installation, Pocket Park will notify you.", image: UIImage(named:
            "red"), buttonText: nil) {
                
                
        }
        
        // Generate the third page, and when the user hits the button we want to handle that the onboarding
        // process has been completed.
        let thirdPage: OnboardingContentViewController = OnboardingContentViewController(title: "Start Exploring", body: "Nearby installations will appear automatically. Tap to begin.", image: UIImage(named:
            "yellow"), buttonText: "Let's Get Started") {
                
                self.handleOnboardingCompletion()
        }
        
        // Create the onboarding controller with the pages and return it.
        let onboardingVC: OnboardingViewController = OnboardingViewController(backgroundImage: UIImage(named: "bg.jpg"), contents: [welcomePage, firstPage, secondPage, thirdPage])
        
        return onboardingVC
    }
    
    func handleOnboardingCompletion() {
        // Now that we are done onboarding, we can set in our NSUserDefaults that we've onboarded now, so in the
        // future when we launch the application we won't see the onboarding again.
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: userHasOnboardedKey)
        
        // Setup the normal root view controller of the application, and set that we want to do it animated so that
        // the transition looks nice from onboarding to normal app.
        setupNormalRootVC(true)
    }
    
    func setupNormalRootVC(animated : Bool) {
        var tabs = UITabBarController()
        var disconnectedViewController = DisconnectedViewController(nibName: "DisconnectedView", bundle: nil)
        var mapViewController = InteractiveMapViewController(nibName: "InteractiveMap", bundle: nil)
        var aboutViewController = AboutViewController(nibName: "AboutView", bundle: nil)
        
        UITabBar.appearance().tintColor = .ITConnectedColor()
        UITabBar.appearance().barStyle = UIBarStyle.Black
        tabs.viewControllers = [mapViewController, disconnectedViewController, aboutViewController]
        
        let mapImage = UIImage(named: "map")
        let nearbyImage = UIImage(named: "nearby")
        let aboutImage = UIImage(named: "main")
        
        mapViewController.tabBarItem = UITabBarItem(title: "Map", image: mapImage, tag: 0)
        disconnectedViewController.tabBarItem = UITabBarItem(title: "Nearby", image: nearbyImage, tag: 1)
        aboutViewController.tabBarItem = UITabBarItem(title: "About", image: aboutImage, tag: 2)
        
        tabs.selectedViewController = disconnectedViewController
        
        askForNotificationPermissionForApplication()
        interactionBeaconManager.startUpdatingLocation()
        
        // If we want to animate it, animate the transition - in this case we're fading, but you can do it
        // however you want.
        if animated {
            UIView.transitionWithView(self.window!, duration: 0.5, options:.TransitionCrossDissolve, animations: { () -> Void in
                self.window!.rootViewController = tabs
                                }, completion:nil)
        }
            // Otherwise we just want to set the root view controller normally.
        else {
              self.window?.rootViewController = tabs
        }
        
    }
    
   }