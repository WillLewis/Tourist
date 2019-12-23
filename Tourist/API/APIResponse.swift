//
//  APIResponse.swift
//  Tourist
//
//  Created by William Lewis on 12/23/19.
//  Copyright © 2019 William Lewis. All rights reserved.
//

import Foundation

struct APIResponse: Decodable {
    let photos: FlickrPhotos
    let stat: String
}
