//
//  ParseCarouselOperation.swift
//  Instagramy
//
//  Created by Alexander Smyshlaev on 2/1/18.
//  Copyright © 2018 Alexander Smyshlaev. All rights reserved.
//

import UIKit

class ParseCarouselOperation: Operation {
    let json: [String : Any?]
    let complitionHandler: (PhotoMedia?) -> ()
    
    init(json: [String : Any?], complition: @escaping (PhotoMedia?) -> ()) {
        self.json = json
        complitionHandler = complition
    }
    
    override func main() {
        guard let type = json["type"] as? String, type == "image" else {
            complitionHandler(nil)
            return
        }
        
        guard let images = json["images"] as? [String: Any?],
            let thumbnail = images["thumbnail"] as? [String: Any?],
            let standartResulution = images["standard_resolution"] as? [String: Any?] else {
                complitionHandler(nil)
                return
        }
        
        guard let thumbnailUrlString = thumbnail["url"] as? String,
            let standartResulutionUrlString = standartResulution["url"] as? String else {
                complitionHandler(nil)
                return
        }
        
        guard let thumbnailUrl = URL(string: thumbnailUrlString),
            let standartResulutionUrl = URL(string: standartResulutionUrlString) else {
                complitionHandler(nil)
                return
        }
        
        complitionHandler(PhotoMedia(standartResolutionUrl: standartResulutionUrl, thumbnailUrl: thumbnailUrl))
    }
}
