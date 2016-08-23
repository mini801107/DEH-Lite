//
//  SplitViewController.swift
//  mapTest3
//
//  Created by 蔡佳旅 on 2016/6/1.
//  Copyright © 2016年 蔡佳旅. All rights reserved.
//

import UIKit

class SplitViewController: UISplitViewController {

    var filteredString = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //let topNavigationVC = self.viewControllers[0] as! UINavigationController
        //let downNavigationVC = self.viewControllers[1] as! UINavigationController
        
        //let masterVC = topNavigationVC.topViewController as! MasterViewController
        //let mapVC = downNavigationVC.topViewController as! MapViewController
        //masterVC.filteredString = self.filteredString
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        YourLeftVC *masterViewController = (YourLeftVC *) [[self.viewControllers objectAtIndex:0] topViewController];
//        YourRightVC *detailViewController = [self.viewControllers objectAtIndex:1];
//
//        masterViewController.delegate = detailViewController;
//
//    }
 

}
