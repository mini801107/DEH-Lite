//
//  MasterViewController.swift
//  mapTest3
//
//  Created by 蔡佳旅 on 2016/6/1.
//  Copyright © 2016年 蔡佳旅. All rights reserved.
//

import UIKit
import CoreLocation
import SwiftyJSON

class MasterViewController: UITableViewController {

    var ListArray = Array<String>()
    var dataArray = Array<JSON>()
    var mapVC = MapViewController()
    var searchingType = "景點"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let downNavigationVC = splitViewController?.viewControllers[1] as! UINavigationController
        
        mapVC = downNavigationVC.topViewController as! MapViewController
        mapVC.delegate = self
       
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ListArray.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Cell")
        cell.textLabel!.text = ListArray[indexPath.row]
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if searchingType == "景點" {
            mapVC.selectedPOIfromtable(indexPath.row)
        }
        else if searchingType == "景線" {
            mapVC.selectedLOIfromtable(indexPath.row)
        }
        else if searchingType == "景區" {
            mapVC.selectedAOIfromtable(indexPath.row)
        }
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension MasterViewController: POIgetDelegate {
    func POIget(JSONString: String, searchType: String) {
        self.searchingType = searchType
        let JSONData = JSONString.dataUsingEncoding(NSUTF8StringEncoding)
        let jsonObj = JSON(data: JSONData!)
        let dataArray = jsonObj["results"].arrayValue
        
        ListArray.removeAll()
        for i in 0 ..< dataArray.count  {
            ListArray.append(dataArray[i]["POI_title"].stringValue)
        }
        tableView.reloadData()
    }
    
    func LOIget(JSONString: String, searchType: String) {
        self.searchingType = searchType
        let JSONData = JSONString.dataUsingEncoding(NSUTF8StringEncoding)
        let jsonObj = JSON(data: JSONData!)
        let dataArray = jsonObj["results"].arrayValue
        
        ListArray.removeAll()
        for i in 0 ..< dataArray.count  {
            ListArray.append(dataArray[i]["routetitle"].stringValue)
        }
        tableView.reloadData()
    }

    func AOIget(JSONString: String, searchType: String) {
        self.searchingType = searchType
        let JSONData = JSONString.dataUsingEncoding(NSUTF8StringEncoding)
        let jsonObj = JSON(data: JSONData!)
        let dataArray = jsonObj["results"].arrayValue
        
        ListArray.removeAll()
        for i in 0 ..< dataArray.count  {
            ListArray.append(dataArray[i]["title"].stringValue)
        }
        tableView.reloadData()
    }
}



