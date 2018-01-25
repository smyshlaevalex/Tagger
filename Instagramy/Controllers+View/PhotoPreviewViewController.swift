//
//  PhotoPreviewViewController.swift
//  Instagramy
//
//  Created by Alexander Smyshlaev on 1/25/18.
//  Copyright © 2018 Alexander Smyshlaev. All rights reserved.
//

import UIKit

class PhotoPreviewViewController: UIViewController {
    @IBOutlet weak var photoImageView: UIImageView!
    
    var photoMedia: PhotoMedia!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        InstagramStore.shared.downloadImage(for: photoMedia) { result in
            switch result {
            case .success(let image):
                DispatchQueue.main.async {
                    self.photoImageView.image = image
                }
            case .error:
                break
            }
        }
    }

}
