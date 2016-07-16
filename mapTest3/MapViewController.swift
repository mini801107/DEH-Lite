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
    func POIget(JSONString: String)
    func LOIget(JSONString: String)
}

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate, UIPickerViewDataSource, UIPickerViewDelegate
{
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var submitWindow: UIView!
    @IBOutlet weak var searchTypeSelector: UIPickerView!
    
    weak var delegate: POIgetDelegate?
    let locationManager = CLLocationManager()
    var currentLocation = CLLocation()
    var distance: Int = 3000
    var dataArray = Array<JSON>()
    var searchingType: String = "景點"
    var annotationInfoButton = true
    var keyData : NSData?
    var LOIinfoArray = Array<JSON>()
    var POIinfoArray = Array<JSON>()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        submitWindow.hidden = true
        submitWindow.layer.cornerRadius = 10
        searchTypeSelector.dataSource = self
        searchTypeSelector.delegate = self
        
        /* Get current location */
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        
        self.mapView.showsUserLocation = true
        
        /* Long press to get arbitrary position */
        let lpgr = UILongPressGestureRecognizer(target:self, action:#selector(ViewController.handleLongPress(_:)))
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
    
    /* definitions of searching options */
    var options = ["景點","景線","景區"]
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return options.count
    }
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return options[row]
    }
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.searchingType = options[pickerView.selectedRowInComponent(0)]
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
        if self.mapView.annotations.count > 1 {
            self.mapView.removeAnnotations(self.mapView.annotations)
        }
        
        /* Send HTTP GET request */
        if searchingType == "景點" {
            self.annotationInfoButton = true
            let nearby_poi_aes_function = "http://deh.csie.ncku.edu.tw/dehencode/json/nearbyPOIs_AES.php"
            let client_ip = "http://deh.csie.ncku.edu.tw/deh/functions/get_client_ip.php"
            
            var url = nearby_poi_aes_function + "?"
            url += ("lat=" + "\(currentLocation.coordinate.latitude)")
            url += ("&lng=" + "\(currentLocation.coordinate.longitude)")
            url += ("&dist=" + "\(distance)")
            url += ("&userlat=" + "\(currentLocation.coordinate.latitude)")
            url += ("&userlng=" + "\(currentLocation.coordinate.longitude)")
            
            Alamofire.request(.GET, url)
                .validate()
                .responseString { responseData  in
                    let getData = responseData.result.value!
                
                    Alamofire.request(.GET, client_ip)
                        .validate()
                        .responseString(){ responseIp in
                            let getIp = String(responseIp.result.value!)
                            let IpArr = getIp.componentsSeparatedByString(".")
                            let key:[UInt8] = [UInt8(IpArr[0])!, UInt8(IpArr[1])!, UInt8(IpArr[2])!, UInt8(IpArr[3])!,
                                UInt8(IpArr[3])!, UInt8(IpArr[2])!, UInt8(IpArr[1])!, UInt8(IpArr[0])!,
                                UInt8(IpArr[1])!, UInt8(IpArr[3])!, UInt8(IpArr[0])!, UInt8(IpArr[2])!,
                                UInt8(IpArr[2])!, UInt8(IpArr[1])!, UInt8(IpArr[0])!, UInt8(IpArr[3])!]
                        
                            self.keyData = NSData(bytes: key as [UInt8], length:16)
                            let decrypted = AESCrypt.decrypt(getData, password: self.keyData)
                            let JSONString = AESCrypt.contentFilter(decrypted)
                        
                            /* plot the POI annotations on map */
                            let JSONData = JSONString.dataUsingEncoding(NSUTF8StringEncoding)
                            let jsonObj = JSON(data: JSONData!)
                            self.dataArray.removeAll()
                            self.dataArray = jsonObj["results"].arrayValue
                            
                            if self.dataArray.count == 0 { return }
                            for i in 0 ..< self.dataArray.count {
                                let x = self.dataArray[i]
                                let poi = POI(title: x["POI_title"].stringValue, coordinate: CLLocationCoordinate2D(latitude:x["latitude"].doubleValue, longitude:x["longitude"].doubleValue))
                                self.mapView.addAnnotation(poi)
                            }
                        
                            self.delegate?.POIget(JSONString) //send POI data to master view controller
                            self.submitWindow.hidden = true
                        
                            /* zoom in the map and place the firsh POI in center */
                            let center = CLLocationCoordinate2D(latitude: self.dataArray[0]["latitude"].doubleValue, longitude: self.dataArray[0]["longitude"].doubleValue)
                            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
                            self.mapView.setRegion(region, animated: true)
                    }
            }
        }
        else if searchingType == "景線" {
            self.annotationInfoButton = false
            let nearby_loi_aes_function = "http://deh.csie.ncku.edu.tw/dehencode/json/nearbyLois_AES.php"
            let client_ip = "http://deh.csie.ncku.edu.tw/deh/functions/get_client_ip.php"
            
            var url = nearby_loi_aes_function + "?"
            url += ("lat=" + "\(currentLocation.coordinate.latitude)")
            url += ("&lng=" + "\(currentLocation.coordinate.longitude)")
            url += ("&dist=" + "\(distance)")
            url += ("&userlat=" + "\(currentLocation.coordinate.latitude)")
            url += ("&userlng=" + "\(currentLocation.coordinate.longitude)")
            
            Alamofire.request(.GET, url)
                .validate()
                .responseString { responseData  in
                    let getData = responseData.result.value!
                    
                    Alamofire.request(.GET, client_ip)
                        .validate()
                        .responseString(){ responseIp in
                            let getIp = String(responseIp.result.value!)
                            let IpArr = getIp.componentsSeparatedByString(".")
                            let key:[UInt8] = [UInt8(IpArr[0])!, UInt8(IpArr[1])!, UInt8(IpArr[2])!, UInt8(IpArr[3])!,
                                UInt8(IpArr[3])!, UInt8(IpArr[2])!, UInt8(IpArr[1])!, UInt8(IpArr[0])!,
                                UInt8(IpArr[1])!, UInt8(IpArr[3])!, UInt8(IpArr[0])!, UInt8(IpArr[2])!,
                                UInt8(IpArr[2])!, UInt8(IpArr[1])!, UInt8(IpArr[0])!, UInt8(IpArr[3])!]
                            
                            self.keyData = NSData(bytes: key as [UInt8], length:16)
                            let decrypted = AESCrypt.decrypt(getData, password: self.keyData)
                            let JSONString = AESCrypt.contentFilter(decrypted)
                            
                            /* plot the first POI annotation in each LOIs on map */
                            let JSONData = JSONString.dataUsingEncoding(NSUTF8StringEncoding)
                            let jsonObj = JSON(data: JSONData!)
                            self.dataArray.removeAll()
                            self.dataArray = jsonObj["results"].arrayValue
                            if self.dataArray.count == 0 { return }
                            
                            for i in 0 ..< self.dataArray.count {
                                let id = self.dataArray[i]["routeid"].stringValue
                                let loi_sequence_aes_function = "http://deh.csie.ncku.edu.tw/dehencode/json/LOIsequence_AES.php" + "?id=" + id
                        
                                Alamofire.request(.GET, loi_sequence_aes_function)
                                    .responseString() { responseLoiData in
                                        let getLoiData = responseLoiData.result.value!
                                       
                                        let LoiDecrypted = AESCrypt.decrypt(getLoiData, password: self.keyData)
                                        let LoiJSONString = AESCrypt.contentFilter(LoiDecrypted)
                                        
                                        let LoiJSONData = LoiJSONString.dataUsingEncoding(NSUTF8StringEncoding)
                                        let LoijsonObj = JSON(data: LoiJSONData!)
                                        let LoidataArray = LoijsonObj["POIsequence"].arrayValue
                                        
                                        let poi = POI(title: self.dataArray[i]["routetitle"].stringValue, coordinate: CLLocationCoordinate2D(latitude:LoidataArray[0]["latitude"].doubleValue, longitude:LoidataArray[0]["longitude"].doubleValue))
                                        self.mapView.addAnnotation(poi)
                                        
                                        /* zoom in the map and place the firsh LOI in center */
                                        if i == 0 {
                                            let center = CLLocationCoordinate2D(latitude: LoidataArray[0]["latitude"].doubleValue, longitude: LoidataArray[0]["longitude"].doubleValue)
                                            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
                                            self.mapView.setRegion(region, animated: true)
                                        }
                                }
                            }
                            
                            self.delegate?.LOIget(JSONString) //send LOI data to master view controller
                            self.submitWindow.hidden = true
                    }
            }
            
        }
        else if searchingType == "景區" {
            
            
        }
    }
    
    
    // MARK : - Location Delegate Methods
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        currentLocation = locations.last!
        
        print("latitude = \(currentLocation.coordinate.latitude), longitude = \(currentLocation.coordinate.longitude)\n")
        
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
            var view: MKPinAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? MKPinAnnotationView{
                dequeuedView.annotation = annotation
                view = dequeuedView
                view.canShowCallout = true
                view.calloutOffset = CGPoint(x: -5, y: 5)
                if self.annotationInfoButton == true {
                    view.rightCalloutAccessoryView = UIButton(type: UIButtonType.DetailDisclosure) as UIView
                }
            } else {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = true
                view.calloutOffset = CGPoint(x: -5, y: 5)
                if self.annotationInfoButton == true {
                    view.rightCalloutAccessoryView = UIButton(type: UIButtonType.DetailDisclosure) as UIView
                }
            }
            return view
        }
        return nil
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
                if searchingType == "景線" {
                    for i in 0 ..< self.POIinfoArray.count {
                        let x = self.POIinfoArray[i]
                        if x["POI_title"].stringValue == String(sender!) {
                            destinationVC.POIinfo = x
                            break
                        }
                    }
                }
                else if searchingType == "景區" {
                        
                }
                
            }
        }
    }
    
    // MARK : - Zoom into selected POI
    func selectedPOIfromtable(index: Int)
    {
        if searchingType == "景點" {
            let center = CLLocationCoordinate2D(latitude: self.dataArray[index]["latitude"].doubleValue, longitude: self.dataArray[index]["longitude"].doubleValue)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001))
        
            let POItitle = self.dataArray[index]["POI_title"].stringValue
            var annotationIndex = Int()
            for i in 0 ..< self.mapView.annotations.count {
                if self.mapView.annotations[i].title! == POItitle{
                    annotationIndex = i
                    break
                }
            }
            self.mapView.setRegion(region, animated: true)
            self.mapView.selectAnnotation(self.mapView.annotations[annotationIndex], animated: true)
        }
        else if searchingType == "景線" {
            self.annotationInfoButton = true
            if self.mapView.annotations.count > 1 {
                self.mapView.removeAnnotations(self.mapView.annotations)
            }
            
            let id = self.dataArray[index]["routeid"].stringValue
            let loi_sequence_aes_function = "http://deh.csie.ncku.edu.tw/dehencode/json/LOIsequence_AES.php" + "?id=" + id
                    
            Alamofire.request(.GET, loi_sequence_aes_function)
                .responseString() { responseLoiData in
                    let getLoiData = responseLoiData.result.value!
                            
                    let LoiDecrypted = AESCrypt.decrypt(getLoiData, password: self.keyData)
                    let LoiJSONString = AESCrypt.contentFilter(LoiDecrypted)
                    let LoiJSONData = LoiJSONString.dataUsingEncoding(NSUTF8StringEncoding)
                    let LoiJSONObj = JSON(data: LoiJSONData!)
                    self.LOIinfoArray.removeAll()
                    self.LOIinfoArray = LoiJSONObj["POIsequence"].arrayValue
                    
                    self.POIinfoArray.removeAll()
                    for i in 0 ..< self.LOIinfoArray.count {
                        let POIid = self.LOIinfoArray[i]["POIid"].stringValue
                        let poi_aes_function = "http://deh.csie.ncku.edu.tw/dehencode/json/poi_AES.php" + "?id=" + POIid
                        
                        Alamofire.request(.GET, poi_aes_function)
                            .responseString() { responsePoiData in
                                let getPoiData = responsePoiData.result.value!
                        
                                let PoiDecrypted = AESCrypt.decrypt(getPoiData, password: self.keyData)
                                let PoiJSONString = AESCrypt.contentFilter(PoiDecrypted)
                                let PoiJSONData = PoiJSONString.dataUsingEncoding(NSUTF8StringEncoding)
                                let PoiJSONObj = JSON(data: PoiJSONData!)
                                let PoiJSONArray = PoiJSONObj["results"].arrayValue
                                self.POIinfoArray.append(PoiJSONArray[0])
                                
                                let poi = POI(title: PoiJSONArray[0]["POI_title"].stringValue, coordinate: CLLocationCoordinate2D(latitude:PoiJSONArray[0]["latitude"].doubleValue, longitude:PoiJSONArray[0]["longitude"].doubleValue))
                                self.mapView.addAnnotation(poi)
                                
                                /* zoom in the map and place the firsh POI in center */
                                if i == 0 {
                                    let center = CLLocationCoordinate2D(latitude: PoiJSONArray[0]["latitude"].doubleValue, longitude: PoiJSONArray[0]["longitude"].doubleValue)
                                    let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                                    self.mapView.setRegion(region, animated: true)
                                    self.mapView.selectAnnotation(self.mapView.annotations.first!, animated: true)
                                }
                        }
                    }
            }
        }
        else if searchingType == "景區" {
            
        }
    }
    
    // MARK : - Long Press Delegate Methods
    var previousAnnotation = MKPointAnnotation()
    func handleLongPress(gestureReconizer: UILongPressGestureRecognizer)
    {
        if gestureReconizer.state != UIGestureRecognizerState.Ended
        {
            let touchLocation = gestureReconizer.locationInView(mapView)
            let locationCoordinate = mapView.convertPoint(touchLocation, toCoordinateFromView: mapView)
            
            //create an MKPointAnnotation object
            let newAnnotation = MKPointAnnotation()
            newAnnotation.coordinate = locationCoordinate
            newAnnotation.title = "You tapped at"
            newAnnotation.subtitle = String(format: "(%.6f, %6f)", locationCoordinate.latitude, locationCoordinate.longitude)
            
            if previousAnnotation.title != nil {
                mapView.removeAnnotation(previousAnnotation)
            }
            mapView.addAnnotation(newAnnotation)
            previousAnnotation = newAnnotation
            
            return
        }
        if gestureReconizer.state != UIGestureRecognizerState.Began{
            return
        }
    }
}


