//
//  InteractiveMapViewController.swift
//  interactron
//
//  Created by Tom Arthur on 3/6/15.
//  Copyright (c) 2015 Tom Arthur. All rights reserved.
//

import UIKit
import MapKit

class InteractiveMapViewController: UIViewController, UIToolbarDelegate, UINavigationBarDelegate, MKMapViewDelegate  {
    
    let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
    
    @IBOutlet weak var mapView: MKMapView!
    var placesObjects = [AnyObject]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        zoomUserLocation()

        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.setUserTrackingMode(.Follow, animated: true);
    }
    
    override func viewWillAppear(animated: Bool) {
        makeNavigationBar()

    }
    
    override func viewDidAppear(animated: Bool) {
        addInteractiveGeoPoints()
        
    }

    
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .TopAttached
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    func makeNavigationBar () {
        
        // Create the navigation bar
        let navigationBar = UINavigationBar(frame: CGRectMake(0, 20, self.view.frame.size.width, 44)) // Offset by 20 pixels vertically to take the status bar into account
        navigationBar.barStyle = .Black
        navigationBar.delegate = self;
        
        // Create a navigation item with a title
        let navigationItem = UINavigationItem()
        navigationItem.title = "Installations"
        navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont(name: "OtterFont", size: 25)!]
        
        navigationBar.items = [navigationItem]
        
        // Make the navigation bar a subview of the current view controller
        self.view.addSubview(navigationBar)
    }
    

    func zoomUserLocation() {

        let spanX = 0.007
        let spanY = 0.007
        var userRegion = MKCoordinateRegion(center: mapView.userLocation.coordinate, span: MKCoordinateSpanMake(spanX, spanY))
        mapView.setRegion(userRegion, animated: true)
    
    }
    
    // TO DO: GROUP POINTS
    func addInteractiveGeoPoints(){
        
        //println("COUNT of num: \(self.mapView.annotations.count)")
        // User's location
        let userGeoPoint = PFGeoPoint(latitude:mapView.userLocation.coordinate.latitude, longitude:mapView.userLocation.coordinate.latitude)
        
        // Create a query for places
        var query = PFQuery(className: "installations")
        query.fromLocalDatastore()
        // Interested in locations near user.
        query.whereKey("location", nearGeoPoint:userGeoPoint)
        // Limit what could be a lot of points.
        query.limit = 10
        // Final list of objects
        
        query.findObjectsInBackgroundWithBlock
            {
                (objects: [AnyObject]!, error: NSError!) -> Void in
                if error == nil
                {
                    self.placesObjects = objects
                    for object in self.placesObjects {
                        var annotation = MKPointAnnotation()
                        let currentPFObject = object as PFObject
                        
                        if let locationGeopoint = currentPFObject["location"] as? PFGeoPoint {
                            annotation.coordinate = CLLocationCoordinate2DMake(locationGeopoint.latitude, locationGeopoint.longitude)
                            annotation.title = currentPFObject["name"] as String
                            
                            if let locationDetail = currentPFObject["locationString"] as? String {
                                annotation.subtitle = locationDetail
                            }
                            
                            if let downcastArray = self.mapView.annotations as? [MKPointAnnotation] {
                                if contains(downcastArray, annotation) == false{
                                  self.mapView.addAnnotation(annotation)
                                }
                            }
                        }
                    }

                } else {
                    NSNotificationCenter.defaultCenter().postNotificationName("parseError", object: nil)
                    NSLog("Unable to find geopoints")
                    NSLog("Error: %@ %@", error, error.userInfo!)
                }
        }
    }
    
    func mapView(mapView: MKMapView!, didUpdateUserLocation
        userLocation: MKUserLocation!) {
            mapView.centerCoordinate = userLocation.location.coordinate
    }

}
