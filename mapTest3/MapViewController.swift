//
//  MapViewController.swift
//  mapTest3
//
//  Created by 蔡佳旅 on 2016/6/3.
//  Copyright © 2016年 蔡佳旅. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation //for current location
import Foundation
import Alamofire
import SwiftyJSON

protocol POIgetDelegate: class {
    func POIget(JSONString: String, searchType: String)
    func LOIget(JSONString: String, searchType: String)
    func AOIget(JSONString: String, searchType: String)
    func clearTable()
}

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate, UIPickerViewDataSource, UIPickerViewDelegate
{
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var submitWindow: UIView!
    @IBOutlet weak var searchLocationSelector: UIPickerView!
    @IBOutlet weak var searchTypeSelector: UIPickerView!
    
    weak var delegate: POIgetDelegate?
    let locationManager = CLLocationManager()
    var currentLocation = CLLocation()
    var distance: Int = 3000
    var dataArray = Array<JSON>()
    var searchingLocation: String = "所在位置"
    var searchingType: String = "景點"
    var annotationInfoButton = true
    var LOIinfoArray = Array<JSON>()
    var POIinfoArray = Array<JSON>()
    var AOIinfoArray = Array<JSON>()
    let sendhttprequest = SendHttpRequest()
    var username: String?
    var password: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        submitWindow.hidden = true
        submitWindow.layer.cornerRadius = 10
        searchTypeSelector.dataSource = self
        searchTypeSelector.delegate = self
        searchLocationSelector.dataSource = self
        searchLocationSelector.delegate = self
        infoButton.hidden = true
        
        /* Get current location */
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        
        self.mapView.showsUserLocation = true
        
        /* Long press to get arbitrary position */
        let lpgr = UILongPressGestureRecognizer(target:self, action:#selector(MapViewController.handleLongPress(_:)))
        lpgr.minimumPressDuration = 0.5
        lpgr.delaysTouchesBegan = true
        lpgr.delegate = self
        self.mapView.addGestureRecognizer(lpgr)
        
        self.mapView.delegate = self
    }
    
    
    //    override func didReceiveMemoryWarning() {
    //        super.didReceiveMemoryWarning()
    //        // Dispose of any resources that can be recreated.
    //    }
    
    /* definitions of searching types & location pickerview */
    var location_options = ["所在位置", "指定位置"]
    var type_options = ["景點","景線","景區"]
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == 0 {
            return location_options.count
        }
        else {
            return type_options.count
        }
    }
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView.tag == 0 {
            return location_options[row]
        }
        else {
            return type_options[row]
        }
    }
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView.tag == 0 {
            self.searchingLocation = location_options[pickerView.selectedRowInComponent(0)]
        }
        else {
            self.searchingType = type_options[pickerView.selectedRowInComponent(0)]
        }
    }
    
    /* definitions and functions of components in submit window */
    @IBOutlet weak var displayLocationText: UILabel!
    @IBOutlet weak var distanceValueText: UITextField!
    @IBOutlet weak var distanceSlider: UISlider!

    @IBAction func cancelButtonTapped(sender: AnyObject) {
        submitWindow.hidden = true
    }
    
    @IBAction func searchingRadiusChanged(sender: AnyObject) {
        let currentValue = Int(distanceSlider.value)
        self.distance = currentValue*1000
        distanceValueText.text = "搜尋半徑 (0-10km) : "+"\(currentValue)"
    }
    
    @IBAction func searchButtonTapped(sender: AnyObject) {
        submitWindow.hidden = false
        submitWindow.alpha = 0.8
        displayLocationText.text = "(\(currentLocation.coordinate.latitude), \(currentLocation.coordinate.longitude))"
    }

    @IBAction func submitButtonTapped(sender: AnyObject) {
        infoButton.hidden = true
        if self.mapView.annotations.count > 1 {
            self.mapView.removeAnnotations(self.mapView.annotations)
        }
        
        if searchingLocation == "所在位置" {
            SearchDataFromServer(currentLocation.coordinate)
            self.submitWindow.hidden = true
        }
        else {
            self.delegate?.clearTable()
            self.submitWindow.hidden = true
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.requestWhenInUseAuthorization()
            self.locationManager.startUpdatingLocation()
            
            self.mapView.showsUserLocation = true
            
            let alert = UIAlertController(title: "選取指定位置", message: "請在地圖上長按欲搜尋位置", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "確認", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
    }
    
    @IBAction func myPoiButtonTapped(sender: AnyObject) {
        if username == nil {
            let alert = UIAlertController(title: "您的身份為訪客", message: "請先登入", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "確認", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        else {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            alert.addAction(UIAlertAction(title: "景點", style: .Default, handler: { action in
                self.searchingType = "景點"
                if self.mapView.annotations.count > 1 {
                    self.mapView.removeAnnotations(self.mapView.annotations)
                }
                self.GetUserPoiFromServer(self.currentLocation.coordinate)
            }))
            alert.addAction(UIAlertAction(title: "景線", style: .Default, handler: { action in
                self.searchingType = "景線"
                if self.mapView.annotations.count > 1 {
                    self.mapView.removeAnnotations(self.mapView.annotations)
                }
                self.GetUserLoiFromServer(self.currentLocation.coordinate)
            }))
            alert.addAction(UIAlertAction(title: "景區", style: .Default, handler: { action in
                self.searchingType = "景區"
                if self.mapView.annotations.count > 1 {
                    self.mapView.removeAnnotations(self.mapView.annotations)
                }
                self.GetUserAoiFromServer(self.currentLocation.coordinate)
            }))
            
            let popover = alert.popoverPresentationController
            popover?.sourceView = view
            popover?.sourceRect = CGRect(x: 460, y: 30, width: 30, height: 30)
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    // MARK : - Location Delegate Methods
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        currentLocation = locations.last!
        
        let center = CLLocationCoordinate2D(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
        
        self.mapView.setRegion(region, animated: true)
        self.locationManager.stopUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Errors: " + error.localizedDescription)
    }
    
    // MARK : - Adding Annotations Methods
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?
    {
        if let annotation = annotation as? POI {
            let identifier = "pin"
            var view: MKAnnotationView
            let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
            if dequeuedView == nil {
                view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            }
            else {
                dequeuedView!.annotation = annotation
                view = dequeuedView!
            }
            
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: -5, y: 5)
            if self.annotationInfoButton == true {
                view.rightCalloutAccessoryView = UIButton(type: UIButtonType.DetailDisclosure) as UIView
            }
            
            /* Resize image */
            let pinImg = UIImage(named: "pin_40.png")
//            let size = CGSize(width: 40, height: 40)
//            UIGraphicsBeginImageContext(size)
//            pinImg?.drawInRect(CGRectMake(0, 0, size.width, size.height))
//            let resizedImg = UIGraphicsGetImageFromCurrentImageContext()
//            UIGraphicsEndImageContext()
            view.image = pinImg
            
            let size = pinImg!.size
            if annotation.sequence > 0 {
                let number : NSString = "\(annotation.sequence)"
                
                let textColor = UIColor.blackColor()
                let textFont = UIFont(name: "Helvetica Bold", size: 16)!
                let textFontAttributes = [NSFontAttributeName: textFont, NSForegroundColorAttributeName: textColor]
                
                let scale = UIScreen.mainScreen().scale
                UIGraphicsBeginImageContextWithOptions(pinImg!.size, false, scale)
                
                pinImg?.drawInRect(CGRectMake(0, 0, size.width, size.height))
                var rect: CGRect
                if annotation.sequence >= 10 {
                    rect = CGRectMake(7, 5, size.width, size.height)
                }
                else {
                    rect = CGRectMake(11, 5, size.width, size.height)
                }
                number.drawInRect(rect, withAttributes: textFontAttributes)
                let numImg : UIImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                view.image = numImg
            }

            return view
        }
        return nil
    }
    
    // MARK : - Send HTTP request to get POI/LOI/AOI data from server
    func SearchDataFromServer(coordinate: CLLocationCoordinate2D)
    {
        print("latitude = \(coordinate.latitude), longitude = \(coordinate.longitude)\n")
        
        if searchingType == "景點" {
            self.annotationInfoButton = true
            let nearby_poi_function = "https://api.deh.csie.ncku.edu.tw/api/v1/pois"
            var url = nearby_poi_function + "?"
            url += ("lat=" + "\(coordinate.latitude)")
            url += ("&lng=" + "\(coordinate.longitude)")
            url += ("&dis=" + "\(distance)")
            
            self.sendhttprequest.authorization(){ token in
                self.sendhttprequest.getNearbyData(url, token: token!){ JSONString in
                    /* plot the POI annotations on map */
                    let JSONData = JSONString!.dataUsingEncoding(NSUTF8StringEncoding)
                    let jsonObj = JSON(data: JSONData!)
                    self.dataArray.removeAll()
                    self.dataArray = jsonObj["results"].arrayValue
                    
                    if self.dataArray.count == 0 { return }
                    for i in 0 ..< self.dataArray.count {
                        let x = self.dataArray[i]
                        let poi = POI(title: x["POI_title"].stringValue, coordinate: CLLocationCoordinate2D(latitude:x["latitude"].doubleValue, longitude:x["longitude"].doubleValue), sequence: 0)
                        self.mapView.addAnnotation(poi)
                    }
                    
                    self.delegate?.POIget(JSONString!, searchType: self.searchingType) //send POI data to master view controller
                    
                    /* zoom in the map and place the firsh POI in center */
                    let center = CLLocationCoordinate2D(latitude: self.dataArray[0]["latitude"].doubleValue, longitude: self.dataArray[0]["longitude"].doubleValue)
                    let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
                    self.mapView.setRegion(region, animated: true)
                }
            }
        }
        else if searchingType == "景線" {
            self.annotationInfoButton = false
            let nearby_loi_function = "https://api.deh.csie.ncku.edu.tw/api/v1/lois"
            
            var url = nearby_loi_function + "?"
            url += ("lat=" + "\(coordinate.latitude)")
            url += ("&lng=" + "\(coordinate.longitude)")
            
            self.sendhttprequest.authorization(){ token in
                self.sendhttprequest.getNearbyData(url, token: token!){ JSONString in
                    /* plot the first POI annotation in each LOIs on map */
                    let JSONData = JSONString!.dataUsingEncoding(NSUTF8StringEncoding)
                    let jsonObj = JSON(data: JSONData!)
                    self.dataArray.removeAll()
                    self.dataArray = jsonObj["results"].arrayValue
                    
                    if self.dataArray.count == 0 { return }
                    for i in 0 ..< self.dataArray.count {
                        let POIset = self.dataArray[i]["POI_set"].arrayValue
                        let poi = POI(title: self.dataArray[i]["LOI_title"].stringValue, coordinate: CLLocationCoordinate2D(latitude:POIset[0]["latitude"].doubleValue, longitude:POIset[0]["longitude"].doubleValue), sequence: 0)
                        self.mapView.addAnnotation(poi)
                        
                        /* zoom in the map and place the firsh LOI in center */
                        if i == 0 {
                            let center = CLLocationCoordinate2D(latitude: POIset[0]["latitude"].doubleValue, longitude: POIset[0]["longitude"].doubleValue)
                            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
                            self.mapView.setRegion(region, animated: true)
                        }
                    }
                    
                    self.delegate?.LOIget(JSONString!, searchType: self.searchingType) //send LOI data to master view controller
                }
            }
        }
        else if searchingType == "景區" {
            self.annotationInfoButton = false
            let nearby_aoi_function = "https://api.deh.csie.ncku.edu.tw/api/v1/aois"
            
            var url = nearby_aoi_function + "?"
            url += ("lat=" + "\(coordinate.latitude)")
            url += ("&lng=" + "\(coordinate.longitude)")
            
            self.sendhttprequest.authorization(){ token in
                self.sendhttprequest.getNearbyData(url, token: token!){ JSONString in
                    /* plot the first POI annotation in each LOIs on map */
                    let JSONData = JSONString!.dataUsingEncoding(NSUTF8StringEncoding)
                    let jsonObj = JSON(data: JSONData!)
                    self.dataArray.removeAll()
                    self.dataArray = jsonObj["results"].arrayValue
                    
                    if self.dataArray.count == 0 { return }
                    for i in 0 ..< self.dataArray.count {
                        let POIset = self.dataArray[i]["POI_set"].arrayValue
                        let poi = POI(title: self.dataArray[i]["AOI_title"].stringValue, coordinate: CLLocationCoordinate2D(latitude:POIset[0]["latitude"].doubleValue, longitude:POIset[0]["longitude"].doubleValue), sequence: 0)
                        self.mapView.addAnnotation(poi)
                        
                        /* zoom in the map and place the firsh LOI in center */
                        if i == 0 {
                            let center = CLLocationCoordinate2D(latitude: POIset[0]["latitude"].doubleValue, longitude: POIset[0]["longitude"].doubleValue)
                            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
                            self.mapView.setRegion(region, animated: true)
                        }
                    }
                    self.delegate?.AOIget(JSONString!, searchType: self.searchingType) //send AOI data to master view controller
                }
            }
        }
    }
    
    // MARK : - Send HTTP request to get my POI/LOI/AOI data from server
    func GetUserPoiFromServer(coordinate: CLLocationCoordinate2D)
    {
        self.annotationInfoButton = true
        let nearby_poi_function = "https://api.deh.csie.ncku.edu.tw/api/v1/users/pois"
        var url = nearby_poi_function + "?"
        url += ("lat=" + "\(coordinate.latitude)")
        url += ("&lng=" + "\(coordinate.longitude)")
            
        self.sendhttprequest.authorization(){ token in
            self.sendhttprequest.getUserData(url, token: token!, user: self.username!, pwd: self.password!){ JSONString in
                /* plot the POI annotations on map */
                let JSONData = JSONString!.dataUsingEncoding(NSUTF8StringEncoding)
                let jsonObj = JSON(data: JSONData!)
                self.dataArray.removeAll()
                self.dataArray = jsonObj["results"].arrayValue
                
                if self.dataArray.count == 0 { return }
                for i in 0 ..< self.dataArray.count {
                    let x = self.dataArray[i]
                    let poi = POI(title: x["POI_title"].stringValue, coordinate: CLLocationCoordinate2D(latitude:x["latitude"].doubleValue, longitude:x["longitude"].doubleValue), sequence: 0)
                    self.mapView.addAnnotation(poi)
                }
                    
                self.delegate?.POIget(JSONString!, searchType: self.searchingType) //send POI data to master view controller
                    
                /* zoom in the map and place the firsh POI in center */
                let center = CLLocationCoordinate2D(latitude: self.dataArray[0]["latitude"].doubleValue, longitude: self.dataArray[0]["longitude"].doubleValue)
                let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
                self.mapView.setRegion(region, animated: true)
            }
        }
    }
    
    func GetUserLoiFromServer(coordinate: CLLocationCoordinate2D)
    {
        self.annotationInfoButton = false
        let nearby_loi_function = "https://api.deh.csie.ncku.edu.tw/api/v1/users/lois"
            
        var url = nearby_loi_function + "?"
        url += ("lat=" + "\(coordinate.latitude)")
        url += ("&lng=" + "\(coordinate.longitude)")
            
        self.sendhttprequest.authorization(){ token in
            self.sendhttprequest.getUserData(url, token: token!, user: self.username!, pwd: self.password!){ JSONString in
                /* plot the first POI annotation in each LOIs on map */
                let JSONData = JSONString!.dataUsingEncoding(NSUTF8StringEncoding)
                let jsonObj = JSON(data: JSONData!)
                self.dataArray.removeAll()
                self.dataArray = jsonObj["results"].arrayValue
                
                if self.dataArray.count == 0 { return }
                for i in 0 ..< self.dataArray.count {
                    let POIset = self.dataArray[i]["POI_set"].arrayValue
                    let poi = POI(title: self.dataArray[i]["LOI_title"].stringValue, coordinate: CLLocationCoordinate2D(latitude:POIset[0]["latitude"].doubleValue, longitude:POIset[0]["longitude"].doubleValue), sequence: 0)
                    self.mapView.addAnnotation(poi)
                        
                        /* zoom in the map and place the firsh LOI in center */
                    if i == 0 {
                        let center = CLLocationCoordinate2D(latitude: POIset[0]["latitude"].doubleValue, longitude: POIset[0]["longitude"].doubleValue)
                        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
                        self.mapView.setRegion(region, animated: true)
                    }
                }
                    
                self.delegate?.LOIget(JSONString!, searchType: self.searchingType) //send LOI data to master view controller
            }
        }
    }
    
    func GetUserAoiFromServer(coordinate: CLLocationCoordinate2D)
    {
        self.annotationInfoButton = false
        let nearby_aoi_function = "https://api.deh.csie.ncku.edu.tw/api/v1/users/aois"
            
        var url = nearby_aoi_function + "?"
        url += ("lat=" + "\(coordinate.latitude)")
        url += ("&lng=" + "\(coordinate.longitude)")
        
        self.sendhttprequest.authorization(){ token in
            self.sendhttprequest.getUserData(url, token: token!, user: self.username!, pwd: self.password!){ JSONString in
                /* plot the first POI annotation in each LOIs on map */
                let JSONData = JSONString!.dataUsingEncoding(NSUTF8StringEncoding)
                let jsonObj = JSON(data: JSONData!)
                self.dataArray.removeAll()
                self.dataArray = jsonObj["results"].arrayValue
                    
                if self.dataArray.count == 0 { return }
                for i in 0 ..< self.dataArray.count {
                    let POIset = self.dataArray[i]["POI_set"].arrayValue
                    let poi = POI(title: self.dataArray[i]["AOI_title"].stringValue, coordinate: CLLocationCoordinate2D(latitude:POIset[0]["latitude"].doubleValue, longitude:POIset[0]["longitude"].doubleValue), sequence: 0)
                    self.mapView.addAnnotation(poi)
                        
                    /* zoom in the map and place the firsh LOI in center */
                    if i == 0 {
                        let center = CLLocationCoordinate2D(latitude: POIset[0]["latitude"].doubleValue, longitude: POIset[0]["longitude"].doubleValue)
                        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
                        self.mapView.setRegion(region, animated: true)
                    }
                }
                self.delegate?.AOIget(JSONString!, searchType: self.searchingType) //send AOI data to master view controller
            }
        }
    }

    
    // MARK : - Peform Annotation segue to DetailView
    func mapView(mapView: MKMapView, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl)
    {
        let selectedPOItitle = annotationView.annotation!.title!

        if control == annotationView.rightCalloutAccessoryView {
            performSegueWithIdentifier("MaptoDetailSegue", sender: selectedPOItitle)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "MaptoDetailSegue" {
            if let destinationVC = segue.destinationViewController as? DetailViewController {
                if searchingType == "景點" {
                    for i in 0 ..< self.dataArray.count {
                        let x = self.dataArray[i]
                        if x["POI_title"].stringValue == String(sender!) {
                            destinationVC.POIinfo = x
                            break
                        }
                    }
                }
                else {
                    for i in 0 ..< self.POIinfoArray.count {
                        let x = self.POIinfoArray[i]
                        if x["POI_title"].stringValue == String(sender!) {
                            
                            /* show alert when selecting unpublic POI */
                            if self.POIinfoArray[i]["identifier"].stringValue == "docent" {
                                if self.POIinfoArray[i]["open"].boolValue == false {
                                    let alert = UIAlertController(title: "無法觀看該景點內容", message: "欲知詳情請聯絡作者："+self.POIinfoArray[i]["rights"].stringValue, preferredStyle: .Alert)
                                    alert.addAction(UIAlertAction(title: "確認", style: .Default, handler: nil))
                                    self.presentViewController(alert, animated: true, completion: nil)
                                    
                                    return
                                }
                            }

                            destinationVC.POIinfo = x
                            break
                        }
                    }
                }
            }
        }
        
        if segue.identifier == "MaptoInfoSegue" {
            if let destinationVC = segue.destinationViewController as? InfoViewController {
                destinationVC.desc = String(sender!)
                destinationVC.POIarray = self.POIinfoArray
            }
        }
    }
    
    
    // MARK : - Zoom into selected POI
    func selectedPOIfromtable(index: Int)
    {
        if searchingType == "景點" {
            infoButton.hidden = true
            let center = CLLocationCoordinate2D(latitude: self.dataArray[index]["latitude"].doubleValue, longitude: self.dataArray[index]["longitude"].doubleValue)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001))
        
            let POItitle = self.dataArray[index]["POI_title"].stringValue
            var annotationIndex = Int()
            for i in 0 ..< self.mapView.annotations.count {
                if self.mapView.annotations[i].title! == POItitle {
                    annotationIndex = i
                    break
                }
            }
            self.mapView.setRegion(region, animated: true)
            self.mapView.selectAnnotation(self.mapView.annotations[annotationIndex], animated: true)
        }
        else {
            var annotationIndex = Int()
            for i in 0 ..< self.mapView.annotations.count {
                if self.mapView.annotations[i].title! == self.POIinfoArray[index]["POI_title"].stringValue {
                    annotationIndex = i
                    break
                }
                else if self.mapView.annotations[i].title! == self.POIinfoArray[index]["title"].stringValue {
                    annotationIndex = i
                    break
                }
            }
         
            /* zoom in the map and place the firsh POI in center */
            let center = CLLocationCoordinate2D(latitude: self.POIinfoArray[index]["latitude"].doubleValue, longitude: self.POIinfoArray[index]["longitude"].doubleValue)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            self.mapView.setRegion(region, animated: true)
            self.mapView.selectAnnotation(self.mapView.annotations[annotationIndex], animated: true)
        }
    }
    
    func selectedLOIfromtable(index: Int){
        infoButton.hidden = false
        LOIdescription = self.dataArray[index]["LOI_description"].stringValue
        
        self.annotationInfoButton = true
        if self.mapView.annotations.count > 1 {
            self.mapView.removeAnnotations(self.mapView.annotations)
        }
        
        let POIset = self.dataArray[index]["POI_set"].arrayValue
        self.POIinfoArray.removeAll()
        self.POIinfoArray = [JSON](count:POIset.count, repeatedValue: nil)
        
        self.sendhttprequest.authorization(){ token in
            for i in 0 ..< POIset.count {
                let id = POIset[i]["id"].stringValue
                let specific_poi_function = "https://api.deh.csie.ncku.edu.tw/api/v1/pois/search" + "?q=" + id
                
                self.sendhttprequest.getNearbyData(specific_poi_function, token: token!){ PoiJSONString in
                    let PoiJSONData = PoiJSONString!.dataUsingEncoding(NSUTF8StringEncoding)
                    let PoiJSONObj = JSON(data: PoiJSONData!)
                    let PoiJSONArray = PoiJSONObj["results"].arrayValue
                    self.POIinfoArray[i] = PoiJSONArray[0]
                    
                    let poi = POI(title: PoiJSONArray[0]["POI_title"].stringValue, coordinate: CLLocationCoordinate2D(latitude:PoiJSONArray[0]["latitude"].doubleValue, longitude:PoiJSONArray[0]["longitude"].doubleValue), sequence: i+1)
                    self.mapView.addAnnotation(poi)
                    
                    /* zoom in the map and place the firsh POI in center */
                    if i == 0 {
                        var annotationIndex = Int()
                        for i in 0 ..< self.mapView.annotations.count {
                            if self.mapView.annotations[i].title! == PoiJSONArray[0]["POI_title"].stringValue {
                                annotationIndex = i
                                break
                            }
                        }
                        
                        let center = CLLocationCoordinate2D(latitude: PoiJSONArray[0]["latitude"].doubleValue, longitude: PoiJSONArray[0]["longitude"].doubleValue)
                        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                        self.mapView.setRegion(region, animated: true)
                        self.mapView.selectAnnotation(self.mapView.annotations[annotationIndex], animated: true)
                    }
                }
            }
        }
    }
    
    func selectedAOIfromtable(index: Int){
        infoButton.hidden = false
        AOIdescription = self.dataArray[index]["AOI_description"].stringValue
       
        self.annotationInfoButton = true
        if self.mapView.annotations.count > 1 {
            self.mapView.removeAnnotations(self.mapView.annotations)
        }
        
        let POIset = self.dataArray[index]["POI_set"].arrayValue
        self.POIinfoArray.removeAll()
        self.POIinfoArray = [JSON](count:POIset.count, repeatedValue: nil)

        self.sendhttprequest.authorization(){ token in
            for i in 0 ..< POIset.count {
                let id = POIset[i]["POI_id"].stringValue
                let specific_poi_function = "https://api.deh.csie.ncku.edu.tw/api/v1/pois/search" + "?q=" + id
                
                self.sendhttprequest.getNearbyData(specific_poi_function, token: token!){ PoiJSONString in
                    let PoiJSONData = PoiJSONString!.dataUsingEncoding(NSUTF8StringEncoding)
                    let PoiJSONObj = JSON(data: PoiJSONData!)
                    let PoiJSONArray = PoiJSONObj["results"].arrayValue
                    self.POIinfoArray[i] = PoiJSONArray[0]
                    
                    let poi = POI(title: PoiJSONArray[0]["POI_title"].stringValue, coordinate: CLLocationCoordinate2D(latitude:PoiJSONArray[0]["latitude"].doubleValue, longitude:PoiJSONArray[0]["longitude"].doubleValue), sequence: 0)
                    self.mapView.addAnnotation(poi)
                    
                    /* zoom in the map and place the firsh POI in center */
                    if i == 0 {
                        var annotationIndex = Int()
                        for i in 0 ..< self.mapView.annotations.count {
                            if self.mapView.annotations[i].title! == PoiJSONArray[0]["POI_title"].stringValue {
                                annotationIndex = i
                                break
                            }
                        }
                        
                        let center = CLLocationCoordinate2D(latitude: PoiJSONArray[0]["latitude"].doubleValue, longitude: PoiJSONArray[0]["longitude"].doubleValue)
                        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                        self.mapView.setRegion(region, animated: true)
                        self.mapView.selectAnnotation(self.mapView.annotations[annotationIndex], animated: true)
                    }
                }
            }
        }
    }

    // MARK :- clear all annotations on the map
    func clearAnnotations()
    {
        if self.mapView.annotations.count > 1 {
            self.mapView.removeAnnotations(self.mapView.annotations)
        }
        
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        self.mapView.showsUserLocation = true
    }
    
    // MARK : - display LOI information
    @IBOutlet weak var infoButton: UIButton!
    var LOIdescription = String()
    var AOIdescription = String()
    @IBAction func infoButtonTapped(sender: AnyObject) {
        if searchingType == "景線" {
            performSegueWithIdentifier("MaptoInfoSegue", sender: LOIdescription)
        }
        else if searchingType == "景區" {
            performSegueWithIdentifier("MaptoInfoSegue", sender: AOIdescription)
        }
    }
    
    @IBAction func unwindToMap(segue: UIStoryboardSegue) {
        
    }
    
    // MARK : - Long Press Delegate Methods
    var previousAnnotation = MKPointAnnotation()
    func handleLongPress(gestureReconizer: UILongPressGestureRecognizer)
    {
        if gestureReconizer.state == UIGestureRecognizerState.Began
        {
            let touchLocation = gestureReconizer.locationInView(mapView)
            let locationCoordinate = mapView.convertPoint(touchLocation, toCoordinateFromView: mapView)
            
            //create an MKPointAnnotation object
            let newAnnotation = MKPointAnnotation()
            newAnnotation.coordinate = locationCoordinate
            newAnnotation.title = "您選擇的位置為"
            newAnnotation.subtitle = String(format: "(%.6f, %6f)", locationCoordinate.latitude, locationCoordinate.longitude)
            
            if previousAnnotation.title != nil {
                mapView.removeAnnotation(previousAnnotation)
            }
            mapView.addAnnotation(newAnnotation)
            previousAnnotation = newAnnotation
            
            let alert = UIAlertController(title: "選擇搜尋位置", message: "是否搜尋此位置？", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "確認", style: .Default, handler: { action in
                self.SearchDataFromServer(locationCoordinate)
            }))
            alert.addAction(UIAlertAction(title: "取消", style: .Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            
            return
        }
        if gestureReconizer.state != UIGestureRecognizerState.Began{
            return
        }
    }
}


