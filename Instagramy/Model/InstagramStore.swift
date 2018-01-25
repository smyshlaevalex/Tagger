//
//  InstagramStore.swift
//  Instagramy
//
//  Created by Alexander Smyshlaev on 1/25/18.
//  Copyright © 2018 Alexander Smyshlaev. All rights reserved.
//

import Foundation
import UIKit

class InstagramStore {
    enum Result<T> {
        case success(T)
        case error
    }
    
    let clientId = "<YOUR CLIENT ID>"
    
    static let shared = InstagramStore()
    
    let operationQueue = OperationQueue()
    
    private init() {}
    
    var accessToken: String? = nil {
        didSet {
            UserDefaults.standard.set(accessToken, forKey: "access-token")
        }
    }
    
    func loadLocalAccessToken() {
        accessToken = UserDefaults.standard.string(forKey: "access-token")
    }
    
    func requestMedia(for hashtag: String, complition: @escaping (Result<[PhotoMedia]>) -> ()) {
        guard let accessToken = accessToken else {
            complition(.error)
            return
        }
        
        let session = URLSession.shared
        
        let url = URL(string: "https://api.instagram.com/v1/tags/\(hashtag)/media/recent?access_token=\(accessToken)")!
        
        let task = session.dataTask(with: url) { data, response, error in
            guard let data = data else {
                complition(.error)
                return
            }
            
            guard let jsonObject = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any?] else {
                complition(.error)
                return
            }
            
            guard let dataArray = jsonObject["data"] as? [[String: Any?]],
                let firstData = dataArray.first,
                let carouselMedia = firstData["carousel_media"] as? [[String: Any?]] else {
                complition(.error)
                return
            }
            
            let photoMedias = carouselMedia.flatMap { media -> PhotoMedia? in
                guard let type = media["type"] as? String, type == "image" else {
                    return nil
                }
                
                guard let images = media["images"] as? [String: Any?],
                    let thumbnail = images["thumbnail"] as? [String: Any?],
                    let standartResulution = images["standard_resolution"] as? [String: Any?] else {
                    return nil
                }
                
                guard let thumbnailUrlString = thumbnail["url"] as? String,
                    let standartResulutionUrlString = standartResulution["url"] as? String else {
                        return nil
                }
                
                guard let thumbnailUrl = URL(string: thumbnailUrlString),
                    let standartResulutionUrl = URL(string: standartResulutionUrlString) else {
                        return nil
                }
                
                return PhotoMedia(standartResolutionUrl: standartResulutionUrl, thumbnailUrl: thumbnailUrl)
            }
            
            complition(.success(photoMedias))
        }
        
        task.resume()
    }
    
    func downloadThumbnails(for photoMedias: [PhotoMedia], complition: @escaping ([UIImage]) -> ()) {
        DispatchQueue.global().async {
            var images = [URL: UIImage]()
            
            let session = URLSession.shared
            
            for photoMedia in photoMedias {
                self.operationQueue.addOperation {
                    let semaphore = DispatchSemaphore(value: 0)
                    
                    let task = session.dataTask(with: photoMedia.thumbnailUrl) { data, response, error in
                        defer {
                            semaphore.signal()
                        }
                        
                        guard let data = data,
                            let image = UIImage(data: data) else {
                            return
                        }
                        
                        images[photoMedia.thumbnailUrl] = image
                    }
                    
                    task.resume()
                    
                    semaphore.wait()
                }
            }
            
            self.operationQueue.waitUntilAllOperationsAreFinished()
            
            let sortedImages = images.sorted { item1, item2 in
                let index1 = photoMedias.index(where: { $0.thumbnailUrl == item1.key })!
                let index2 = photoMedias.index(where: { $0.thumbnailUrl == item2.key })!
                
                return index1 < index2
            } .map { $0.value }
            
            complition(sortedImages)
        }
    }
    
    func downloadImage(for photoMedia: PhotoMedia, complition: @escaping (Result<UIImage>) -> ()) {
        let session = URLSession.shared
        
        let task = session.dataTask(with: photoMedia.standartResolutionUrl) { data, response, error in
            guard let data = data,
                let image = UIImage(data: data) else {
                    complition(.error)
                    return
            }
            
            complition(.success(image))
        }
        
        task.resume()
    }
}
