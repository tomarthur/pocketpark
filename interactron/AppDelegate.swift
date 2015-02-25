//
//  AppDelegate.swift
//  interactron
//
//  Created by Tom Arthur on 2/16/15.
//  Copyright (c) 2015 Tom Arthur. All rights reserved.
//

import UIKit
import CoreLocation



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    var interactionBeaconManager = InteractionBeaconManager()
    var dataManager = DataManager()

    
    let defaults = NSUserDefaults.standardUserDefaults()
    let automaticConnectionKeyConstant = "automaticConnectionUser"
    let settingsBundle = NSBundle.mainBundle().pathForResource("Root", ofType: "plist")
//    let settings = NSDictionary(contentsOfFile: settingsBundle!)

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Parse framework for analytics, data and bug tracking
        ParseCrashReporting.enable()
        Parse.enableLocalDatastore()
//        PFUser.enableAutomaticUser()
        Parse.setApplicationId("yc2HKK3EGe1tDIlvTyY9x2dKhgGaVNai7dQWfvGG",
                clientKey: "dVeENxp57pgP3Zwqlez4U2G8O64B1tXQUBKsgTC1")
        PFAnalytics.trackAppOpenedWithLaunchOptions(launchOptions)
        
        dataManager.start()
        interactionBeaconManager.start()
        
        // stop location when app is open
        interactionBeaconManager.locationManager?.stopUpdatingLocation()
        
        // check to see if user has set automatic mode
        if defaults.objectForKey(automaticConnectionKeyConstant) == nil {
            defaults.setBool(true, forKey: automaticConnectionKeyConstant)
            // TODO: SETTINGS BUNDLE
        }

        askForNotificationPermissionForApplication(application)
        
        var disconnectedViewController = DisconnectedViewController(nibName: "DisconnectedView", bundle: nil)
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        
        if let window = window {
            var backgroundColor: UIColor
            window.backgroundColor = .ITWelcomeColor()
            window.rootViewController = disconnectedViewController
            window.makeKeyAndVisible()
        }
        
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
        interactionBeaconManager.locationManager?.startUpdatingLocation()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        println("entering forground")
        interactionBeaconManager.locationManager?.stopUpdatingLocation()
        
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        interactionBeaconManager.locationManager?.startUpdatingLocation()
    }
    
    func askForNotificationPermissionForApplication(application: UIApplication){
        // Local Notification Registration
        if(application.respondsToSelector("registerUserNotificationSettings:")) {
            application.registerUserNotificationSettings(
                UIUserNotificationSettings(
                    forTypes: UIUserNotificationType.Alert | UIUserNotificationType.Sound,
                    categories: nil
                )
            )
        }
        
    }
    
    func application(application: UIApplication,
        didReceiveLocalNotification notification: UILocalNotification) {
            
//            let appState : UIApplicationState = UIApplication.sharedApplication().applicationState
//
//            if appState != UIApplicationState.Active
//            {
                let friendlyName = notification.userInfo!["friendlyName"] as? String
                let bleName = notification.userInfo!["bleName"] as? String

                if friendlyName != nil && bleName != nil{
                    var requestNotificationDict: [String:String] = ["beaconInteractionBLEName" : bleName!]
                    NSNotificationCenter.defaultCenter().postNotificationName("startInteractionFromNotification", object: self, userInfo: requestNotificationDict)
                } else {
                    /* This is not the notification that we composed */
                }
//            }
            
    }
}