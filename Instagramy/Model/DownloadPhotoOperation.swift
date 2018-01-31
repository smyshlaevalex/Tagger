//
//  DownloadPhotoOperation.swift
//  Instagramy
//
//  Created by Alexander Smyshlaev on 1/30/18.
//  Copyright © 2018 Alexander Smyshlaev. All rights reserved.
//

import UIKit

class DownloadPhotoOperation: AsynchronousOperation {
    let session: URLSession
    let url: URL
    let complitionHandler: (UIImage?) -> ()
    
    init(session: URLSession, url: URL, complition: @escaping (UIImage?) -> ()) {
        self.session = session
        self.url = url
        self.complitionHandler = complition
    }
    
    override func start() {
        super.start()
        
        let task = session.dataTask(with: url) { data, response, error in
            guard let response = response as? HTTPURLResponse,
                response.statusCode == 200,
                error == nil else {
                self.finish(image: nil)
                return
            }
            
            guard let data = data,
                let image = UIImage(data: data) else {
                    self.finish(image: nil)
                    return
            }
            
            self.finish(image: image)
        }
        
        task.resume()
    }
    
    func finish(image: UIImage?) {
        state = .finished
        self.complitionHandler(image)
    }
}
