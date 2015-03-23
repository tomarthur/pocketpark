//
//  InteractiveMapViewController.swift
//  interactron
//
//  Created by Tom Arthur on 3/6/15.
//  Copyright (c) 2015 Tom Arthur. All rights reserved.
//

import UIKit
import MapKit

class InteractiveMapViewController: UIViewController, MKMapViewDelegate, UIToolbarDelegate {
    
    let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var aboutButton: UITabBarItem!
    @IBOutlet weak var mapButton: UITabBarItem!
    @IBOutlet weak var nearbyButton: UITabBarItem!
    
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Assign tab bar item with titles
        let tabBarController = UITabBarController()
        tabBar.selectedItem = self.tabBar.items![0] as? UITabBarItem
        tabBar.tintColor = .ITConnectedColor()
//        tabBar.st
        
        // when datastore and bluetooth are ready
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "addInteractiveGeoPoints:",
            name: "GeoPointDictionaryReady", object: nil)
        
        // build the dictionary of geopoints
        appDelegate.dataManager.dictionaryOfInteractivesWithGeoPoints()
        

        mapView.delegate = self
        mapView.showsUserLocation = true
        zoomUserLocation()

        
    }
    
    override func viewDidAppear(animated: Bool) {
        tabBar.selectedItem = self.tabBar.items![0] as? UITabBarItem
        

    }
    

    
    func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem!) {
        switch item.tag {
        case 0:
            println("cow")
        case 1:
            // Dismiss any modal view controllers.
            self.dismissViewControllerAnimated(false, completion:nil)
            println("1")
            // Dismiss any modal view controllers.
            presentedViewController?.dismissViewControllerAnimated(true, completion: { () in
                println("dismissing past")
                self.dismissViewControllerAnimated(true, completion: nil)
            })
        case 2:
            let aboutViewController:AboutViewController = AboutViewController(
                nibName: "AboutView",bundle: nil)
//            pushViewController(aboutViewController, animated: YES)
            

        default:
            break
        }
        
    }
//    dictionaryOfInteractivesWithGeoPoints/
    
    func zoomUserLocation() {

        let spanX = 0.007
        let spanY = 0.007
        var userRegion = MKCoordinateRegion(center: mapView.userLocation.coordinate, span: MKCoordinateSpanMake(spanX, spanY))
        mapView.setRegion(userRegion, animated: true)
        
        
    }
    
    func addInteractiveGeoPoints(notification: NSNotification){

        println("setting points")
        
        for (name, geopoint) in appDelegate.dataManager.knownInteractivesFromParseWithGeopoints {
            
//            self.SpotLocationLatitudes.append(self.SpotGeoPoints.last?.latitude as CLLocationDegrees!)
//            self.SpotLocationLongitudes.append(self.SpotGeoPoints.last?.longitude as CLLocationDegrees!)
            
            var annotation = MKPointAnnotation()
            println("setting points for \(name):  \(geopoint.latitude), \(geopoint.latitude)")
            annotation.coordinate = CLLocationCoordinate2DMake(geopoint.latitude, geopoint.longitude)
            annotation.title = name
            self.mapView.addAnnotation(annotation)
        }
        


        
    }
    
    func mapView(mapView: MKMapView!, didUpdateUserLocation
        userLocation: MKUserLocation!) {
            mapView.centerCoordinate = userLocation.location.coordinate
    }
    

    
//    @IBAction func zoomIn(sender: AnyObject) {
//    }
    
    
//    @IBAction func changeMapType(sender: AnyObject) {
//    }

}
