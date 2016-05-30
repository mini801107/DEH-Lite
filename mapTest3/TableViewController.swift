//
//  TableViewController.swift
//  mapTest3
//
//  Created by 蔡佳旅 on 2016/5/30.
//  Copyright © 2016年 蔡佳旅. All rights reserved.
//

import UIKit
import CoreLocation
import SwiftyJSON

class TableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var filteredString = String()
    var jsonObj = JSON.null
    var ListArray = Array<String>()
    
    @IBOutlet var POItable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let JSONData = filteredString.dataUsingEncoding(NSUTF8StringEncoding)
        self.jsonObj = JSON(data: JSONData!)
        let dataArray = self.jsonObj["results"].arrayValue
        for i in 0 ..< dataArray.count  {
            self.ListArray.append(dataArray[i]["POI_title"].stringValue)
        }
        
        POItable.dataSource = self
        POItable.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return ListArray.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Cell")
        cell.textLabel!.text = ListArray[indexPath.row]
        return cell
    }

}
