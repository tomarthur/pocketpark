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

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        mapView.showsUserLocation = true
        makeNavigationBar()
    }
    
    override func viewWillAppear(animated: Bool) {
        makeNavigationBar()
       zoomUserLocation()
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
    
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .TopAttached
    }

    override func viewDidAppear(animated: Bool) {
        
        addInteractiveGeoPoints()
    }

    func zoomUserLocation() {

        let spanX = 0.007
        let spanY = 0.007
        var userRegion = MKCoordinateRegion(center: mapView.userLocation.coordinate, span: MKCoordinateSpanMake(spanX, spanY))
        mapView.setRegion(userRegion, animated: true)
        
        
    }
    
    func addInteractiveGeoPoints(){

            for (name, geopoint) in appDelegate.dataManager.knownInteractivesFromParseWithGeopoints {
                var annotation = MKPointAnnotation()

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
