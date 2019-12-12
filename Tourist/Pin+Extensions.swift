//
//  Pin+Extensions.swift
//  Tourist
//
//  Created by William Lewis on 12/11/19.
//  Copyright © 2019 William Lewis. All rights reserved.
//

import Foundation
import CoreData
import MapKit

extension Pin {
    public var coordinate: CLLocationCoordinate2D {
        guard let latitude = latitude, let longitude = longitude else{
            return kCLLocationCoordinate2DInvalid
        }
        
        let latDegrees = CLLocationDegrees((latitude as NSString).doubleValue)
        let longDegrees = CLLocationDegrees((longitude as NSString).doubleValue)
        return CLLocationCoordinate2D(latitude: latDegrees, longitude: longDegrees)
    }
}
