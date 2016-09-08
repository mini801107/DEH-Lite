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

class MasterViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var welcomeMsg: UILabel!
    
    //var ListArray = Array<String>()
    var dataArray = Array<JSON>()
    var mapVC = MapViewController()
    var searchingType = "景點"
    let sendhttprequest = SendHttpRequest()
    var username: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let downNavigationVC = splitViewController?.viewControllers[1] as! UINavigationController
        
        mapVC = downNavigationVC.topViewController as! MapViewController
        mapVC.delegate = self
        mapVC.username = nil
        mapVC.password = nil
        tableView.dataSource = self
        tableView.delegate = self
        
        let loginImg = UIImage(named: "login.png")
        loginButton.setImage(loginImg, forState: .Normal)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArray.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        //let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Cell")
        //cell.textLabel!.text = ListArray[indexPath.row]
        
        let cell = self.tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! CustomCell
        if searchingType == "景點" {
            cell.title.text = dataArray[indexPath.row]["POI_title"].stringValue
        }
        else if searchingType == "景線" {
            cell.title.text = dataArray[indexPath.row]["LOI_title"].stringValue
        }
        else if searchingType == "景區" {
            cell.title.text = dataArray[indexPath.row]["AOI_title"].stringValue
        }
        
        
        let identifier = dataArray[indexPath.row]["identifier"].stringValue
        switch identifier {
            case "user" :
                cell.identifier.image = UIImage(named: "user_50")
                break
            case "expert" :
                cell.identifier.image = UIImage(named: "expert_50")
                break
            case "docent" :
                cell.identifier.image = UIImage(named: "docent_50")
                break
            default :
                cell.identifier.image = UIImage(named: "default_50")
                break
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
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
    
    @IBAction func LoginButtonTapped(sender: AnyObject) {
        if self.username == nil {   // when user does not login
            var userTextField: UITextField?
            var pwdTextField: UITextField?
        
            let loginAlert = UIAlertController(title: "會員登入", message: "請輸入帳號及密碼", preferredStyle: .Alert)
            loginAlert.addAction(UIAlertAction(title: "確認", style: .Default, handler: { action in
                if userTextField!.text! == "" || pwdTextField!.text! == "" {
                    let alert = UIAlertController(title: "登入失敗", message: "帳號或密碼錯誤", preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "確認", style: .Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                }
                else {
                    self.sendhttprequest.authorization(){ token in
                        self.sendhttprequest.userLogin(token!, user: userTextField!.text!, pwd: pwdTextField!.text!){ msg in
                            let msgString = msg!.dataUsingEncoding(NSUTF8StringEncoding)
                            let JSONObj = JSON(data: msgString!)
                            let uname = JSONObj["username"].stringValue
                            if uname != userTextField!.text! {
                                let alert = UIAlertController(title: "登入失敗", message: "帳號或密碼錯誤", preferredStyle: .Alert)
                                alert.addAction(UIAlertAction(title: "確認", style: .Default, handler: nil))
                                self.presentViewController(alert, animated: true, completion: nil)
                            }
                            else {
                                let logoutImg = UIImage(named: "logout.png")
                                self.loginButton.setImage(logoutImg, forState: .Normal)
                                self.username = uname
                                self.mapVC.username = uname
                                self.mapVC.password = pwdTextField!.text!
                                self.welcomeMsg.text = "您現在的身份是：" + uname
                                
                                let alert = UIAlertController(title: "登入成功", message: uname+", 歡迎回來", preferredStyle: .Alert)
                                alert.addAction(UIAlertAction(title: "確認", style: .Default, handler: nil))
                                self.presentViewController(alert, animated: true, completion: nil)
                                
                            }
                        }
                    }
                }
            }))
            loginAlert.addAction(UIAlertAction(title: "取消", style: .Cancel, handler: nil))
            loginAlert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
                textField.placeholder = "帳號"
                textField.secureTextEntry = true
                userTextField = textField
            })
            loginAlert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
                textField.placeholder = "密碼"
                textField.secureTextEntry = true
                pwdTextField = textField
            })
            self.presentViewController(loginAlert, animated: true, completion: nil)
        }
        else {  // when user does login
            let loginImg = UIImage(named: "login.png")
            self.loginButton.setImage(loginImg, forState: .Normal)
            self.username = nil
            self.mapVC.username = nil
            self.mapVC.password = nil
            self.welcomeMsg.text = "您現在的身份是：訪客"
            clearTable()
            self.mapVC.clearAnnotations()
            
            let alert = UIAlertController(title: "登出成功", message: "回到訪客身份", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "確認", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
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

        dataArray.removeAll()
        dataArray = jsonObj["results"].arrayValue

        tableView.reloadData()
    }
    
    func LOIget(JSONString: String, searchType: String) {
        self.searchingType = searchType
        let JSONData = JSONString.dataUsingEncoding(NSUTF8StringEncoding)
        let jsonObj = JSON(data: JSONData!)

        dataArray.removeAll()
        dataArray = jsonObj["results"].arrayValue

        tableView.reloadData()
    }

    func AOIget(JSONString: String, searchType: String) {
        self.searchingType = searchType
        let JSONData = JSONString.dataUsingEncoding(NSUTF8StringEncoding)
        let jsonObj = JSON(data: JSONData!)

        dataArray.removeAll()
        dataArray = jsonObj["results"].arrayValue

        tableView.reloadData()
    }
    
    func clearTable()
    {
        dataArray.removeAll()
        tableView.reloadData()
    }
}



