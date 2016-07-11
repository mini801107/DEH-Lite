//
//  POI.swift
//  mapTest3
//
//  Created by 蔡佳旅 on 2016/6/6.
//  Copyright © 2016年 蔡佳旅. All rights reserved.
//

import Foundation
import MapKit

class POI: NSObject, MKAnnotation {
    let title: String?
    let coordinate: CLLocationCoordinate2D

    init(title: String, coordinate:CLLocationCoordinate2D){
        self.title = title
        self.coordinate = coordinate
        
        super.init()
    }
}