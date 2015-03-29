//
//  InteractiveCardCell.swift
//  PocketPark
//
//  Created by Tom Arthur on 3/22/15.
//
//

import UIKit
import QuartzCore
import MapKit

class InteractiveCardCell: UITableViewCell {

    let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
    
    @IBOutlet weak var interactiveCardView: UIView!
    @IBOutlet weak var interactiveSubCardView: UIView!
    @IBOutlet weak var interactiveLocation: MKMapView!
    @IBOutlet weak var interactiveName: UILabel!
    @IBOutlet weak var interactiveDetails: UILabel!
    @IBOutlet weak var interactiveLastSeen: UILabel!
    
    @IBAction func interactiveStartButton(sender: AnyObject) {
        for (parseBLEName, parseFriendlyName) in appDelegate.dataManager.knownInteractivesFromParseFriendlyNames {
            if parseFriendlyName == interactiveName.text {
                var requestNotificationDict: [String:String] = ["beaconInteractionBLEName" : parseBLEName]
                NSNotificationCenter.defaultCenter().postNotificationName("startInteractionFromNotification", object: self, userInfo: requestNotificationDict)
            }
        }
    }

    @IBAction func interactiveTouchDown(sender: AnyObject) {
        
    }
    
    func loadItem(#title: String, desc: String, coordinates: CLLocationCoordinate2D){
        
        interactiveCardView.backgroundColor = UIColor.clearColor()
        
        interactiveSubCardView.layer.cornerRadius = 10
        interactiveSubCardView.layer.masksToBounds = true


        interactiveName.text = title
        interactiveName.font = UIFont(name:"OtterFont", size: 45)
        interactiveName.minimumScaleFactor = 0.5
        interactiveName.adjustsFontSizeToFitWidth = true

        interactiveName.textAlignment = .Center
        interactiveName.sizeToFit()
        interactiveName.layer.cornerRadius = 10
        interactiveName.layer.masksToBounds = true
        
        interactiveDetails.text = desc
        interactiveDetails.textAlignment = .Center
        interactiveDetails.adjustsFontSizeToFitWidth = true
        
        interactiveLastSeen.text = "Tap To Contact"
        interactiveLastSeen.textColor = UIColor.whiteColor()
        interactiveLastSeen.textAlignment = .Center
        interactiveLastSeen.font = UIFont(name: "HelveticaNeue-Light", size: 12)
        
        
        let spanX = 0.0004
        let spanY = 0.0004
        var interactiveRegion = MKCoordinateRegion(center: coordinates, span: MKCoordinateSpanMake(spanX, spanY))
        interactiveLocation.setRegion(interactiveRegion, animated: false)
        interactiveLocation.scrollEnabled = false
        interactiveLocation.zoomEnabled = false
        interactiveLocation.pitchEnabled = false
        interactiveLocation.rotateEnabled = false
        interactiveLocation.showsUserLocation = true
        interactiveLocation.layer.cornerRadius = 10
        interactiveLocation.layer.masksToBounds = true
        
        var annotation = MKPointAnnotation()
        annotation.coordinate = coordinates
        annotation.title = title
        interactiveLocation.addAnnotation(annotation)
        
        self.contentView.setTranslatesAutoresizingMaskIntoConstraints(true)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String!) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
}