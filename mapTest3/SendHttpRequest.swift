//
//  SendHttpRequest.swift
//  mapTest3
//
//  Created by 蔡佳旅 on 2016/7/22.
//  Copyright © 2016年 蔡佳旅. All rights reserved.
//

import Foundation
import Alamofire

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
}

