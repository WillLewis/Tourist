//
//  FlickrPhoto.swift
//  Tourist
//
//  Created by William Lewis on 12/23/19.
//  Copyright © 2019 William Lewis. All rights reserved.
//

import Foundation

struct FlickrPhoto: Decodable{
    let id: String
    let url: String
    let title: String
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case url = "url_n"
        case title =  "title"
    }
}
