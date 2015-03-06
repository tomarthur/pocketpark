//
//  InteractiveMapViewController.swift
//  interactron
//
//  Created by Tom Arthur on 3/6/15.
//  Copyright (c) 2015 Tom Arthur. All rights reserved.
//

import UIKit
import MapKit

class InteractiveMapViewController: UIViewController, MKMapViewDelegate, UINavigationBarDelegate, UIToolbarDelegate {
    
    let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
    
    
    @IBOutlet weak var mapView: MKMapView!
    
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .TopAttached
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    func closeMap(sender: UIBarButtonItem){
        self.dismissViewControllerAnimated(true, completion:nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // when datastore and bluetooth are ready
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "addInteractiveGeoPoints:",
            name: "GeoPointDictionaryReady", object: nil)
        
        // build the dictionary of geopoints
        appDelegate.dataManager.dictionaryOfInteractivesWithGeoPoints()
        
        makeNavigationBar()
        makeToolbar()
        
        mapView.delegate = self
        mapView.showsUserLocation = true
        zoomUserLocation()

        
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
    
    func makeNavigationBar() {
        // Create the navigation bar
        let navigationBar = UINavigationBar(frame: CGRectMake(0, 20, UIScreen.mainScreen().bounds.width, 44)) // Offset by 20 pixels vertically to take the status bar into account
//        var backgroundColor: UIColor
        navigationBar.barTintColor = .ITWelcomeColor()
        navigationBar.translucent = true
        navigationBar.delegate = self
        
        let navigationItem = UINavigationItem()
        navigationItem.title = "Interactives"
        navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        
        let backButton = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.Plain, target: self, action: "closeMap:")
        backButton.tintColor = UIColor.whiteColor()
        //        backButton.tit = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        navigationItem.leftBarButtonItem = backButton
        
        navigationBar.items = [navigationItem]
        self.view.addSubview(navigationBar)
        
        
    }
    
    func makeToolbar(){
        let toolBar = UIToolbar(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, 44))
        toolBar.barTintColor = .ITWelcomeColor()
        toolBar.translucent = true
        toolBar.delegate = self
        
    }

    
//    @IBAction func zoomIn(sender: AnyObject) {
//    }
    
    
//    @IBAction func changeMapType(sender: AnyObject) {
//    }

}
