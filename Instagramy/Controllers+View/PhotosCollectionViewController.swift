//
//  PhotosCollectionViewController.swift
//  Instagramy
//
//  Created by Alexander Smyshlaev on 1/25/18.
//  Copyright © 2018 Alexander Smyshlaev. All rights reserved.
//

import UIKit


class PhotosCollectionViewController: UICollectionViewController {
    private let photoCellReuseIdentifier = "photoCell"
    
    var photoMedias: [PhotoMedia]?
    var thumbnails: [UIImage]?
    
    weak var activityIndicator: UIActivityIndicatorView?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.searchController = UISearchController(searchResultsController: nil)
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.searchController?.searchBar.delegate = self
        
        if (InstagramStore.shared.accessToken == nil) {
            performSegue(withIdentifier: "showAuthentificationView", sender: nil)
        }
    }
    
    func refresh(with hashtag: String) {
        addActivityIndicator()
        
        InstagramStore.shared.requestMedia(for: hashtag) { result in
            switch result {
            case .success(let photoMedias):
                self.photoMedias = photoMedias
                InstagramStore.shared.downloadThumbnails(for: photoMedias) { images in
                    DispatchQueue.main.async {
                        self.removeActivityIndicator()
                        self.thumbnails = images
                        self.collectionView?.reloadData()
                    }
                }
            case .error:
                DispatchQueue.main.async {
                    self.removeActivityIndicator()
                }
            }
        }
    }
    
    func addActivityIndicator() {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        
        guard let window = UIApplication.shared.keyWindow else {
            return
        }
        
        activityIndicator.center = window.center
        
        window.addSubview(activityIndicator)
        
        activityIndicator.startAnimating()
        
        self.activityIndicator = activityIndicator
        
    }
    
    func removeActivityIndicator() {
        activityIndicator?.removeFromSuperview()
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return thumbnails?.count ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: photoCellReuseIdentifier, for: indexPath) as! PhotoCollectionViewCell
        
        cell.photoImageView.image = thumbnails![indexPath.item]
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showPreview", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "showPreview":
            let destination = segue.destination as! PhotoPreviewViewController
            let indexPath = collectionView!.indexPathsForSelectedItems!.first!
            destination.photoMedia = photoMedias![indexPath.item]
        default:
            break
        }
    }
}

extension PhotosCollectionViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        refresh(with: searchBar.text ?? "")
        navigationItem.searchController?.isActive = false
    }
}
