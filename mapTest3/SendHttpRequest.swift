//
//  SendHttpRequest.swift
//  mapTest3
//
//  Created by 蔡佳旅 on 2016/7/22.
//  Copyright © 2016年 蔡佳旅. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class SendHttpRequest {
    
    func authorization(completion:(String?) -> Void) {
        let par = ["username": "test02", "password": "4d5e2a885578299e5a5902ad295447c6"]
        Alamofire.request(.POST, "https://api.deh.csie.ncku.edu.tw/api/v1/grant", parameters: par)
            .validate()
            .responseString{ responseToken in
                let str = String(responseToken.result.value!)
                let jsonData = str.dataUsingEncoding(NSUTF8StringEncoding)
                let jsonObj = JSON(data: jsonData!)
                let token = jsonObj["token"].stringValue
                completion(token)
        }
    }
    
    func getNearbyData(url: String, token: String, completion:(String?) -> Void) {
        let header = [ "Authorization" : "Token " + token ]
        Alamofire.request(.GET, url, headers: header)
            .validate()
            .responseString{ responseData in
                let str = String(responseData.result.value!)
                completion(str)
        }
    }
    
    func getNearbyData2(url: String, token: String, completion:(String?, Bool) -> Void) {
        let header = [ "Authorization" : "Token " + token ]
        Alamofire.request(.GET, url, headers: header)
            .validate()
            .responseString{ responseData in
                let str = String(responseData.result.value!)
                completion(str, true)
        }
    }
    
    func userLogin(token: String, user: String, pwd: String, completion:(String?) -> Void) {
        let pwd_md5 = md5(string: pwd)
        let par = ["username": user, "password": pwd_md5]
        let header = [ "Authorization" : "Token " + token ]
        
        Alamofire.request(.POST, "https://api.deh.csie.ncku.edu.tw/api/v1/users/login", parameters: par, headers: header)
            .validate()
            .responseString{ responseMsg in
                let str = String(responseMsg.result.value!)
                completion(str)
        }
    }
    
    func getUserData(url: String, token: String, user: String, pwd: String, completion:(String?) -> Void) {
        let pwd_md5 = md5(string:pwd)
        let par = ["username": "cmdhuang", "password": "09800aec13cc2ce32c5cd0a05a2cbdbe"]
        let header = ["Authorization" : "Token " + token]
        
        Alamofire.request(.POST, url, parameters: par, headers: header)
            .validate()
            .responseString{ responseData in
                let str = String(responseData.result.value!)
                completion(str)
        }
    }
    
    func md5(string string: String) -> String {
        var digest = [UInt8](count: Int(CC_MD5_DIGEST_LENGTH), repeatedValue: 0)
        if let data = string.dataUsingEncoding(NSUTF8StringEncoding) {
            CC_MD5(data.bytes, CC_LONG(data.length), &digest)
        }
        
        var digestHex = ""
        for index in 0..<Int(CC_MD5_DIGEST_LENGTH) {
            digestHex += String(format: "%02x", digest[index])
        }
        
        return digestHex
    }
}



