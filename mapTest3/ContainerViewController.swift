//
//  ContainerViewController.swift
//  mapTest3
//
//  Created by 蔡佳旅 on 2016/6/1.
//  Copyright © 2016年 蔡佳旅. All rights reserved.
//

import UIKit

class ContainerViewController: UIViewController {

    var filteredString = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let splitVC = segue.destinationViewController as? SplitViewController {
            splitVC.filteredString = self.filteredString
        }
    }

}
