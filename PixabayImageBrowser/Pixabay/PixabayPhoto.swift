//
//  PixabayPhoto.swift
//  PixabayImageBrowser
//
//  Created by Landon Epps on 4/22/19.
//  Copyright © 2019 Landon Epps. All rights reserved.
//

import UIKit

class PixabayPhoto {
    let id: Int
    let thumbnailURL: URL
    let largeImageURL: URL
    var thumbnailImage: UIImage?
    var largeImage: UIImage?
    
    init(id: Int, thumbnailURL: URL, largeImageURL: URL) {
        self.id = id
        self.thumbnailURL = thumbnailURL
        self.largeImageURL = largeImageURL
    }
}
