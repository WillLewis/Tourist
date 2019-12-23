//
//  FlickrClient.swift
//  Tourist
//
//  Created by William Lewis on 12/23/19.
//  Copyright © 2019 William Lewis. All rights reserved.
//

import Foundation

class FlickrClient {
    
    class func getPhoto(photo: Photo, completion: @escaping (Data?, Error?) -> Void){
        guard let urlString = photo.url else {
            print("problem getting url for photo")
            return
        }
        guard let url = URL(string: urlString) else {
            print("problem converting string to url")
            return
        }
        
        let task =  URLSession.shared.dataTask(with: url) {(data, response, error) in
            DispatchQueue.main.async {
                completion(data, error)
            }
        }
        task.resume()
    }
    
    class func getPhotosByLocation(pin: Pin, completion: @escaping (APIResponse?, Error?) -> Void) {
        let pageLimit = min(pin.pages, 40)
        let pageConstrained = max(pageLimit, 1)
        let randomPage = Int(arc4random_uniform(UInt32(pageConstrained))) + 1
        
        guard let url = buildPhotoURL(lat: pin.latitude, lon: pin.longitude, page: randomPage, pages: Int(pin.pages)) else {
            print("problems building url")
            return
        }
        
        taskForGetRequest(url: url, response: APIResponse.self) {(response, error) in
            if let response =  response {
                completion(response, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    class func taskForGetRequest<ResponseType: Decodable>(url: URL, response: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) {
        
        let task = URLSession.shared.dataTask(with: url) {data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let response = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(response, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                    
                }
            }
        }
        task.resume()
    }
    /// MARK: Helper functions
    class func buildPhotoURL(lat: Double, lon: Double, page: Int, pages: Int)-> URL? {
        var photoURL = URLComponents(string: API.Endpoints.base)!
        photoURL.queryItems = [
            URLQueryItem(name: API.Keys.Method, value: API.Values.Method),
            URLQueryItem(name: API.Keys.APIKey, value: API.Values.APIKey),
            URLQueryItem(name: API.Keys.Lat, value: "\(lat)"),
            URLQueryItem(name: API.Keys.Lon, value: "\(lon)"),
            URLQueryItem(name: API.Keys.PerPage, value: API.Values.PerPage),
            URLQueryItem(name: API.Keys.Format, value: API.Values.Format),
            URLQueryItem(name: API.Keys.Page, value: "\(page)"),
            URLQueryItem(name: API.Keys.NoJSONCallback, value: API.Values.NoJSONCallback),
            URLQueryItem(name: API.Keys.Extras, value: API.Values.Extras)
            ] as [URLQueryItem]
        
        return photoURL.url
    }
}
