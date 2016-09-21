//
//  InfoViewController.swift
//  mapTest3
//
//  Created by 蔡佳旅 on 2016/7/17.
//  Copyright © 2016年 蔡佳旅. All rights reserved.
//

import UIKit
import SwiftyJSON
import MapKit

class InfoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var desc = String()
    var POIarray = Array<JSON>()
    var mapVC = MapViewController()

    @IBOutlet weak var LOIdescription: UITextView!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        
        LOIdescription.text = desc
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Implement TableView data source
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return POIarray.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 50
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Cell")
        cell.textLabel!.text = POIarray[indexPath.row]["title"].stringValue
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("InfotoMapUnwind", sender: indexPath.row)
    }
    
    // MARK : - Peform unwind segue to MapView
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "InfotoMapUnwind" {
            if let destinationVC = segue.destinationViewController as? MapViewController {
                let index = sender!.integerValue
                destinationVC.selectedPOIfromtable(index)
            }
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
