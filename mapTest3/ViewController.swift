//
//  ViewController.swift
//  mapTest3
//
//  Created by 蔡佳旅 on 2016/5/4.
//  Copyright © 2016年 蔡佳旅. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation //for current location
import Foundation
import CryptoSwift
import Alamofire

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate, UIPickerViewDataSource, UIPickerViewDelegate
{
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var optionsWindow: UIView!
    @IBOutlet weak var locationSelector: UIPickerView!
    
    let locationManager = CLLocationManager()
    var currentLocation = CLLocation()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        optionsWindow.hidden = true
        optionsWindow.layer.cornerRadius = 10
        //optionsWindow.layer.masksToBounds = true
        locationSelector.dataSource = self
        locationSelector.delegate = self
        
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
    }

//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }

    
    var options = ["Search current location","Search specific location"]
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return options.count
    }
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return options[row]
    }
    
    @IBOutlet weak var distanceValueText: UITextField!
    @IBOutlet weak var distanceSlider: UISlider!
    @IBAction func optionsWindowCancel(sender: AnyObject) {
        optionsWindow.hidden = true
    }
    
    @IBAction func distanceSliderChanged(sender: AnyObject) {
        let currentValue = Int(distanceSlider.value)
        distanceValueText.text = "Searching radius (0-10km) : "+"\(currentValue)"
    }
    @IBAction func searchOptions(sender: AnyObject) {
        optionsWindow.hidden = false
        optionsWindow.alpha = 0.8
    }
    
    
    @IBAction func searchButtonTapped(sender: AnyObject) {
        let nearby_poi_aes_function = "http://deh.csie.ncku.edu.tw/dehencode/json/nearbyPOIs_AES.php"
        let client_ip = "http://deh.csie.ncku.edu.tw/deh/functions/get_client_ip.php"
        
        var url = nearby_poi_aes_function + "?"
        url += ("lat=" + "\(currentLocation.coordinate.latitude)")
        url += ("&lng=" + "\(currentLocation.coordinate.longitude)")
        url += ("&dist=" + "1000")
        url += ("&userlat=" + "\(currentLocation.coordinate.latitude)")
        url += ("&userlng=" + "\(currentLocation.coordinate.longitude)")
       
        let url2 = "http://deh.csie.ncku.edu.tw/dehencode/json/nearbyPOIs_AES.php?lat=22.9971675355331&lng=120.221438673254&dist=10000.0&num=50&userlat=22.9971675355331&userlng=120.221438673254&clang=en"
        
        /* Send HTTP GET request */
        Alamofire.request(.GET, url)
            //.validate()
            .responseString { responseData  in
                let getData = responseData.result.value!
                let decodedData = getData.stringByReplacingOccurrencesOfString("\r\n", withString: "")
               
                Alamofire.request(.GET, client_ip)
                .validate()
                .responseString(){ responseIp in
                    let getIp = String(responseIp.result.value!)
                    let IpArr = getIp.componentsSeparatedByString(".")
                    let key:[UInt8] = [UInt8(IpArr[0])!, UInt8(IpArr[1])!, UInt8(IpArr[2])!, UInt8(IpArr[3])!,
                                       UInt8(IpArr[3])!, UInt8(IpArr[2])!, UInt8(IpArr[1])!, UInt8(IpArr[0])!,
                                       UInt8(IpArr[1])!, UInt8(IpArr[3])!, UInt8(IpArr[0])!, UInt8(IpArr[2])!,
                                       UInt8(IpArr[2])!, UInt8(IpArr[1])!, UInt8(IpArr[0])!, UInt8(IpArr[3])!]
                    
                    let keyData = NSData(bytes: key as [UInt8], length:16)
                    let k = AESCrypt.genarateKEYFromIP(getIp)
                    print("keyData = \(keyData)")
                    //let iv = "DEH2014@CSIENCKU"
                    let decrypted = AESCrypt.decrypt(getData, password: k)
                    //print(getData)
                    print("decrypted = \(decrypted)")
                    
                    //let decrypted = try! decodedData.decrypt(AES(key: key, iv: iv))
                    //let decrypted = try! decodedData.decryptBase64ToString(AES(key: key, iv: iv))
                    //let decrypted = try! decodedData.aesDecrypt(key, iv: iv)
                    
                    //print("dec:\(decrypted)")
                    //print("\(key)\nlength = \(key.characters.count)")
                }
        }
    }
        
//        let myURL = NSURL(string: url)
//        let request = NSMutableURLRequest(URL: myURL!)
//        request.HTTPMethod = "GET"
//        
//        var encryptedData = NSData()
//        var decodedString = NSString()
//        let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
//            if error != nil
//            {
//                print("error = \(error)")
//                return
//            }
//            encryptedData = data!
//            decodedString = NSString(data: data!, encoding: NSUTF8StringEncoding)!
//            decodedString = decodedString.stringByReplacingOccurrencesOfString("\r\n", withString: "")
//            //print("\ntextFormWeb = \(decodedString)")
//
//        })
//        task.resume()
//        
//        //get IP for key
//        let myURL_ip = NSURL(string: client_ip)
//        let request_ip = NSMutableURLRequest(URL: myURL_ip!)
//        request_ip.HTTPMethod = "GET"
//        
//        var ipString = NSString()
//        var ipStringArr = Array<String>()
//        let task_ip = NSURLSession.sharedSession().dataTaskWithRequest(request_ip, completionHandler: {data, response, error -> Void in
//            if error != nil
//            {
//                print("error = \(error)")
//                return
//            }
//            ipString = NSString(data: data!, encoding: NSUTF8StringEncoding)!
//            print("ipString = \(ipString)")
//            ipStringArr = ipString.componentsSeparatedByString(".")
//            print("\n\n\(ipStringArr)")
//        })
//        task_ip.resume()
//        
//        print("\n\n\(ipStringArr)")
//        let key = String(ipString)
//        let iv = "DEH2014@CSIENCKU"
        //let data = String(decodedString)
        //let dec = try! data.aesDecrypt(key, iv: iv)
        //let decrypted = try! data.decryptBase64ToString(AES(key: key, iv: iv, blockMode: .CBC, padding: NoPadding()))
        //let decrypted = try! encryptedData.decrypt(AES(key: key, iv: iv))
        //print("dec:\(decrypted)") // string to encrypt
//    }
    
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
    
    // MARK : - Long Press Delegate Mathods
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

extension String {
    func aesEncrypt(key: String, iv: String) throws -> String{
        let data = self.dataUsingEncoding(NSUTF8StringEncoding)
        let enc = try AES(key: key, iv: iv, blockMode:.CBC).encrypt(data!.arrayOfBytes())
        let encData = NSData(bytes: enc, length: Int(enc.count))
        let base64String: String = encData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0));
        let result = String(base64String)
        return result
    }
    func aesDecrypt(key: String, iv: String) throws -> String {
        let data = NSData(base64EncodedString: self, options: NSDataBase64DecodingOptions(rawValue: 0))
        let dec = try AES(key: key, iv: iv, blockMode:.CBC).decrypt(data!.arrayOfBytes())
        let decData = NSData(bytes: dec, length: Int(dec.count))
        print(decData)
        let result = String(data: decData, encoding: NSUTF8StringEncoding)
        return String(result)
    }
}



