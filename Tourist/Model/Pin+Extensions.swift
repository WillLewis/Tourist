//
//  Pin+Extensions.swift
//  Tourist
//
//  Created by William Lewis on 12/11/19.
//  Copyright © 2019 William Lewis. All rights reserved.
//

import Foundation
import MapKit

extension Pin {
    public var coordinate: CLLocationCoordinate2D {
        set {
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
        get{
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        
    }
}
