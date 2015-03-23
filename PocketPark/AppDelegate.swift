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
    var interactionBeaconManager = InteractionBeaconManager()   // Core Location
    var dataManager = DataManager()                             // Parse Data

    
    let defaults = NSUserDefaults.standardUserDefaults()
    let userHasOnboardedKey = "user_has_onboarded"
    


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // configure Hockey App
        BITHockeyManager.sharedHockeyManager().configureWithIdentifier("3697b3f570362d842ec8c975151e6bc3")
        BITHockeyManager.sharedHockeyManager().startManager()
        BITHockeyManager.sharedHockeyManager().authenticator.authenticateInstallation()
        
        // Parse framework for analytics, data and bug tracking
        ParseCrashReporting.enable()
        Parse.enableLocalDatastore()
        Parse.setApplicationId("yc2HKK3EGe1tDIlvTyY9x2dKhgGaVNai7dQWfvGG",
                clientKey: "dVeENxp57pgP3Zwqlez4U2G8O64B1tXQUBKsgTC1")
        PFAnalytics.trackAppOpenedWithLaunchOptions(launchOptions)
        PFUser.enableAutomaticUser()
        PFUser.currentUser().incrementKey("RunCount")
        PFUser.currentUser().saveInBackground()
        
        // get data from Parse
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
        
        interactionBeaconManager.locationManager?.startUpdatingLocation()
        
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

        interactionBeaconManager.locationManager?.stopUpdatingLocation()
        
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        interactionBeaconManager.locationManager?.startUpdatingLocation()
    }
    
    func askForNotificationPermissionForApplication(){
        // Local Notification Registration
        if(UIApplication.sharedApplication().respondsToSelector("registerUserNotificationSettings:")) {
            UIApplication.sharedApplication().registerUserNotificationSettings(
                UIUserNotificationSettings(
                    forTypes: UIUserNotificationType.Alert | UIUserNotificationType.Sound,
                    categories: nil
                )
            )
        }
        
    }
    
    func application(application: UIApplication,
        didReceiveLocalNotification notification: UILocalNotification) {
            

            let friendlyName = notification.userInfo!["friendlyName"] as? String
            let bleName = notification.userInfo!["bleName"] as? String

            if friendlyName != nil && bleName != nil{
                var requestNotificationDict: [String:String] = ["beaconInteractionBLEName" : bleName!]
                NSNotificationCenter.defaultCenter().postNotificationName("startInteractionFromNotification", object: self, userInfo: requestNotificationDict)
            } else {
                /* This is not the notification that we composed */
            }
            
    }
    
    func generateOnboardingViewController() -> OnboardingViewController {
        // generate the welcome page
        let welcomePage: OnboardingContentViewController = OnboardingContentViewController(title: "Control the World", body: "Pocket Theme Park is your gateway to interactive experiences embedded in the world around you.", image: UIImage(named:
            "blue"), buttonText: nil) {
        }

        // Generate the first page...
        let firstPage: OnboardingContentViewController = OnboardingContentViewController(title: "Discover Installations Around You Automatically", body: "Enableing location services will help you find nearby installations.", image: UIImage(named:
            "blue"), buttonText: "Enable Location Services") {
                self.interactionBeaconManager.requestAuthorization()
        }
        
        // Generate the second page...
        let secondPage: OnboardingContentViewController = OnboardingContentViewController(title: "Get Notified", body: "Get notified when an installations is nearby.", image: UIImage(named:
            "red"), buttonText: "Enable Notifications") {
                self.askForNotificationPermissionForApplication();
        }
        
        // Generate the third page, and when the user hits the button we want to handle that the onboarding
        // process has been completed.
        let thirdPage: OnboardingContentViewController = OnboardingContentViewController(title: "Adventure", body: "You can add your own experiences.", image: UIImage(named:
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
        var disconnectedViewController = DisconnectedViewController(nibName: "DisconnectedView", bundle: nil)
        
        // start location services
        interactionBeaconManager.startUpdatingLocation()
        
        // If we want to animate it, animate the transition - in this case we're fading, but you can do it
        // however you want.
        if animated {
            UIView.transitionWithView(self.window!, duration: 1.0, options:.TransitionCrossDissolve, animations: { () -> Void in
                self.window!.rootViewController = disconnectedViewController
                }, completion:nil)
        }
            // Otherwise we just want to set the root view controller normally.
        else {
            self.window?.rootViewController = disconnectedViewController;
        }
    }
    
   }