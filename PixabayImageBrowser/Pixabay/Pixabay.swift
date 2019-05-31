//
//  Pixabay.swift
//  PixabayImageBrowser
//
//  Created by Landon Epps on 4/22/19.
//  Copyright © 2019 Landon Epps. All rights reserved.
//

import UIKit

struct PixabaySearchResult: Codable {
    struct Hit: Codable {
        let id: Int
        let largeImageURL: URL
        let previewURL: URL
    }
    let hits: [Hit]
}

class Pixabay {
    private static let baseURL = "https://pixabay.com/api/"
    
    static func search(_ searchQuery: String, completionHandler: @escaping (Result<[PixabayPhoto], ImageSearchError>) -> Void) {
        // escape the query
        let escapedQuery = searchQuery.replacingOccurrences(of: " ", with: "+")
                                      .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
        // build the request
        var requestURL = URLComponents(string: baseURL)!
        requestURL.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "q", value: escapedQuery),
            URLQueryItem(name: "safesearch", value: "true"),
            URLQueryItem(name: "per_page", value: "200")
        ]
        
        let task = URLSession.shared.dataTask(with: requestURL.url!) { data, response, error in
            
            if let error = error {
                // cocoa error (network failure, etc.)
                DispatchQueue.main.async {
                    completionHandler(.failure(.error(error)))
                }
                return
            }
            
            guard response != nil else {
                // empty response
                DispatchQueue.main.async {
                    completionHandler(.failure(.unknownResponse))
                }
                return
            }
            
            guard let data = data else {
                // empty data
                DispatchQueue.main.async {
                    completionHandler(.failure(.unknownResponse))
                }
                return
            }

            guard let hits = try? JSONDecoder().decode(PixabaySearchResult.self, from: data).hits else {
                // failed to decode response
                DispatchQueue.main.async {
                    completionHandler(.failure(.decodingError))
                }
                return
            }
            
            // build array of photos
            let photos: [PixabayPhoto] = hits.compactMap() { hit in
                return PixabayPhoto(id: hit.id, thumbnailURL: hit.previewURL, largeImageURL: hit.largeImageURL)
            }
            
            DispatchQueue.main.async {
                completionHandler(.success(photos))
            }
        }
        task.resume()
    }
}

// TODO: Flesh out errors
enum ImageSearchError: Error {
    case error(Error), unknownResponse, decodingError
}
