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

    override func viewDidLoad() {
        super.viewDidLoad()

        // when datastore and bluetooth are ready
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "addInteractiveGeoPoints:",
            name: "GeoPointDictionaryReady", object: nil)

        mapView.delegate = self
        mapView.showsUserLocation = true
        zoomUserLocation()
        
    }
    
    
    

    
    
    func zoomUserLocation() {

        let spanX = 0.007
        let spanY = 0.007
        var userRegion = MKCoordinateRegion(center: mapView.userLocation.coordinate, span: MKCoordinateSpanMake(spanX, spanY))
        mapView.setRegion(userRegion, animated: true)
        
        
    }
    
    func addInteractiveGeoPoints(notification: NSNotification){

        println("grrrrr points")
        
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
