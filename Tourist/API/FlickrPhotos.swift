//
//  FlickrPhotos.swift
//  Tourist
//
//  Created by William Lewis on 12/23/19.
//  Copyright © 2019 William Lewis. All rights reserved.
//

import Foundation

struct FlickrPhotos: Decodable {
    let pages: Int
    let photo: [FlickrPhoto]
}
