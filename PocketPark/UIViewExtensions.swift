//
//  UIViewExtensions.swift
//  PocketPark
//
//  Created by Tom Arthur on 3/29/15.
//
//

import Foundation
import UIKit

extension UIView {
    func fadeIn() {
        // Move our fade out code from earlier
        UIView.animateWithDuration(1.0, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            self.alpha = 1.0 // Instead of a specific instance of, say, birdTypeLabel, we simply set [thisInstance] (ie, self)'s alpha
            }, completion: nil)
    }
    
    func fadeOut() {
        UIView.animateWithDuration(1.0, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            self.alpha = 0.0
            }, completion: nil)
    }
}