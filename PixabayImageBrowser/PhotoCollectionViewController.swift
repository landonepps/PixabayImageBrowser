//
//  PhotoCollectionViewController.swift
//  PixabayImageBrowser
//
//  Created by Landon Epps on 4/22/19.
//  Copyright © 2019 Landon Epps. All rights reserved.
//

import UIKit

class PhotoCollectionViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchDescriptionImage: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var searchBar = UISearchBar()

    private var photos = [PixabayPhoto]()
    private let segueIdentifier = "goLargePhotoViewController"
    private let reuseIdentifier = "PhotoCell"
    private let sectionInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
    private let paddingSize: CGFloat = 1.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set up search bar
        self.navigationItem.titleView = searchBar
        searchBar.delegate = self
        searchBar.autocapitalizationType = .none
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // destination should always be a LargePhotoViewController
        guard let photoViewController = segue.destination as? LargePhotoViewController else {
            fatalError()
        }
        
        // set up the destination VC
        if segue.identifier == segueIdentifier {
            if let indexPaths = collectionView.indexPathsForSelectedItems {
                let indexPath = indexPaths[0]
                photoViewController.photoIndex = indexPath.item
                photoViewController.photos = photos
            }
        }
    }
}

// MARK: - UICollectionViewDataSource

extension PhotoCollectionViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoCell
        
        // configure the cell

        // set the imageView to match the current thumbnail
        let photo = photos[indexPath.item]
        cell.imageId = photo.id
        cell.imageView.image = photo.thumbnailImage
        
        // if there is no current thumbnail, load it
        if photo.thumbnailImage == nil {
            // load image asynchronously on the global queue to avoid lag
            DispatchQueue.global(qos: .userInitiated).async {
                guard
                    let imageData = try? Data(contentsOf: photo.thumbnailURL),
                    let image = UIImage(data: imageData) else {
                        return
                }
                
                // save the loaded image in the photo object
                photo.thumbnailImage = image
                
                // Only update the imageView if the cell's current photo id matches
                // Since cells are reused, it's possible it will be in a different place
                // before the image finishes loading.
                if cell.imageId == photo.id {
                    DispatchQueue.main.async {
                        cell.imageView.image = image
                    }
                }
            }
        }
        
        return cell
    }
}

// MARK: - UISearchBarDelegate

extension PhotoCollectionViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // make sure search isn't empty
        guard let searchText = searchBar.text else { return }
        
        // clear the collection view
        photos.removeAll()
        self.collectionView?.reloadData()
        
        // show activity indicator while waiting for results
        activityIndicator.startAnimating()

        Pixabay.search(searchText) { result in
            // stop activity indicator
            self.activityIndicator.stopAnimating()

            switch (result) {
            case .failure(let error):
                print("Error: \(error)")
            case .success(let photos):
                // update collection view
                self.photos = photos
                self.collectionView?.reloadData()
            }
        }

        // hide the image describing the search
        searchDescriptionImage.isHidden = true
        // hide the keyboard
        searchBar.resignFirstResponder()
    }
}
