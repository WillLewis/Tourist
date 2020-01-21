// Holds the constants
//  API.swift
//  Tourist
//
//  Created by William Lewis on 12/23/19.
//  Copyright © 2019 William Lewis. All rights reserved.
//

import Foundation

struct API {
    struct Endpoints {
        static let base = "https://www.flickr.com/services/rest"
    }
    
    struct Keys {
        static let Method = "method"
        static let APIKey = "api_key"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
        static let PerPage = "per_page"
        static let Page = "page"
        static let Lat = "lat"
        static let Lon = "lon"
        static let Extras = "extras"
    }
    
    struct Values {
        static let Method = "flickr.photos.search"
        static let APIKey = "5b1f6379e60f7e5865bd9120b7c0fc52"
        static let Format = "json"
        static let NoJSONCallback = "1"
        static let PerPage = "20"
        static let Extras = "url_n"
    }
    
}
