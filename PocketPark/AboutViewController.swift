//
//  AboutViewController.swift
//  
//
//  Created by Tom Arthur on 2/23/15.
//
//

import UIKit

class AboutViewController: UIViewController {

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
   
        tabBar.tintColor = .ITConnectedColor()
        
        self.view.backgroundColor = .ITWelcomeColor()
    }

    override func viewDidAppear(animated: Bool) {
        tabBar.selectedItem = self.tabBar.items![2] as? UITabBarItem
        

    }
    
    func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem!) {
        switch item.tag {
        case 0:
            let interactiveMapViewController:InteractiveMapViewController = InteractiveMapViewController(
                nibName: "InteractiveMap",bundle: nil)
            
            presentViewController(interactiveMapViewController, animated: false, completion: nil)
            
        case 1:
            // Dismiss any modal view controllers.
            self.dismissViewControllerAnimated(false, completion:nil)
            // Dismiss any modal view controllers.
            presentedViewController?.dismissViewControllerAnimated(true, completion: { () in
                println("dismissing past")
                self.dismissViewControllerAnimated(true, completion: nil)
            })
            
            println("1")
        case 2:

            println("2")
        default:
            break
        }
        
    }

    
}
