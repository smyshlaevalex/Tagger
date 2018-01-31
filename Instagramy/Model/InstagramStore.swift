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
        
        let hashtag = hashtag.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "")
        
        let session = URLSession.shared
        
        let url = URL(string: "https://api.instagram.com/v1/tags/\(hashtag)/media/recent?access_token=\(accessToken)")!
        
        let task = session.dataTask(with: url) { data, response, error in
            guard let response = response as? HTTPURLResponse,
                response.statusCode == 200,
                error == nil else {
                    complition(.error)
                    return
            }
            
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
            
            var photoMedias = [PhotoMedia]()
            
            let lock = NSLock()
            
            for media in carouselMedia {
                let parseCarouselOperation = ParseCarouselOperation(json: media) { photoMedia in
                    if let photoMedia = photoMedia {
                        lock.lock()
                        photoMedias.append(photoMedia)
                        lock.unlock()
                    }
                }
                
                self.operationQueue.addOperation(parseCarouselOperation)
            }
            
            self.operationQueue.waitUntilAllOperationsAreFinished()
            
            complition(.success(photoMedias))
        }
        
        task.resume()
    }
    
    func downloadThumbnails(for photoMedias: [PhotoMedia], complition: @escaping ([UIImage]) -> ()) {
        DispatchQueue.global().async {
            var images = [URL: UIImage]()
            
            let lock = NSLock()
            
            let session = URLSession.shared
            
            for photoMedia in photoMedias {
                let downloadPhotoOperation = DownloadPhotoOperation(session: session, url: photoMedia.thumbnailUrl) { image in
                    lock.lock()
                    images[photoMedia.thumbnailUrl] = image
                    lock.unlock()
                }
                
                self.operationQueue.addOperation(downloadPhotoOperation)
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
        
        let downloadPhotoOperation = DownloadPhotoOperation(session: session, url: photoMedia.standartResolutionUrl) { image in
            if let image = image {
                complition(.success(image))
            } else {
                complition(.error)
            }
        }
        
        downloadPhotoOperation.start()
    }
}
