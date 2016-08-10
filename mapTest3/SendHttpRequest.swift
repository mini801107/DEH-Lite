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
    
    func GetDataFromURL(url: String, key: NSData, completion:(String?) -> Void) {
        Alamofire.request(.GET, url)
            .validate()
            .responseString{ responseData in
                let getData = String(responseData.result.value!)
                let decrypted = AESCrypt.decrypt(getData, password: key)
                let JSONString = AESCrypt.contentFilter(decrypted)
                completion(JSONString)
        }
    }

    func GetKeyFromURL(url: String, completion:(NSData?) -> Void){
        Alamofire.request(.GET, url)
            .validate()
            .responseString{ responseIp in
                let getIP = String(responseIp.result.value!)
                let IPArr = getIP.componentsSeparatedByString(".")
                let key:[UInt8] = [UInt8(IPArr[0])!, UInt8(IPArr[1])!, UInt8(IPArr[2])!, UInt8(IPArr[3])!,
                    UInt8(IPArr[3])!, UInt8(IPArr[2])!, UInt8(IPArr[1])!, UInt8(IPArr[0])!,
                    UInt8(IPArr[1])!, UInt8(IPArr[3])!, UInt8(IPArr[0])!, UInt8(IPArr[2])!,
                    UInt8(IPArr[2])!, UInt8(IPArr[1])!, UInt8(IPArr[0])!, UInt8(IPArr[3])!]
                let keyData = NSData(bytes: key as [UInt8], length:16)
                completion(keyData)
        }
    }
    
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
    
    func userLogin(token: String, user: String, pwd: String, completion:(String?) -> Void) {
        let pwd_md5 = md5(string: pwd)
        let par = ["username": user, "password": pwd_md5]
        let header = [ "Authorization" : "Token " + token ]
        print(pwd_md5)
        Alamofire.request(.POST, "https://api.deh.csie.ncku.edu.tw/api/v1/users/login", parameters: par, headers: header)
            .validate()
            .responseString{ responseMsg in
                let str = String(responseMsg.result.value!)
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



