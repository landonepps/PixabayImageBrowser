//
//  LargePhotoViewController.swift
//  PixabayImageBrowser
//
//  Created by Landon Epps on 4/23/19.
//  Copyright © 2019 Landon Epps. All rights reserved.
//

import UIKit
import Photos

class LargePhotoViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var photos: [PixabayPhoto]?
    var photoIndex: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // make sure we can access the photo
        guard
            let photoIndex = photoIndex,
            let photo = photos?[photoIndex] else {
                return
        }
        
        // if large image has been loaded before, use that
        if photo.largeImage != nil {
            imageView.image = photo.largeImage
            return
        }
        
        // otherwise load the image from the url
        activityIndicator.startAnimating()
        DispatchQueue.main.async {
            guard
                let imageData = try? Data(contentsOf: photo.largeImageURL),
                let image = UIImage(data: imageData) else {
                    return
            }
            
            self.activityIndicator.stopAnimating()
            photo.largeImage = image
            self.imageView.image = photo.largeImage
        }
    }
    
    // MARK: - Saving Photos
    
    @IBAction func saveAction(_ sender: UIBarButtonItem) {
        guard
            let photoIndex = photoIndex,
            let image = photos?[photoIndex].largeImage else { return }
        
        let authStatus = PHPhotoLibrary.authorizationStatus()
        
        switch(authStatus) {
        case .authorized:
            // if authorized save the photo
            savePhoto(image)
        case .notDetermined:
            // if user has not been asked, ask them
            PHPhotoLibrary.requestAuthorization() { granted in
                switch(granted) {
                case .authorized:
                    // the user authorized us, save the photo
                    self.savePhoto(image)
                default:
                    // the user didn't authorize us, show alert
                    self.showAuthAlert()
                }
            }
        default:
            // the user didn't authorize us, show alert
            showAuthAlert()
        }
    }
    
    /// Save image to photo library
    /// - Assumes authorization to access photo library
    private func savePhoto(_ image: UIImage) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }, completionHandler: { success, error in
            if success {
                // image successfully saved, let the user know
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Success",
                                                            message: "Photo saved!",
                                                            preferredStyle: .alert)
                    self.present(alertController, animated: true, completion: nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        alertController.dismiss(animated: true)
                    }
                }
            }
            else if let error = error {
                print("Error saving photo: \(String(describing: error))")
            } else {
                print("Error saving photo")
            }
        })
    }
    
    /// Show warning when user has denied giving permissions
    private func showAuthAlert() {
        // get bundle name
        guard let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") else {
            print("Error: Unable to get bundle name")
            return
        }
        
        // build alert message
        let message = """
        You need to give me permission to save the photo.
        
        1. Open Settings
        2. Tap "\(bundleName)" > Photos
        3. Select "Read and Write"
        """
        let alertController = UIAlertController(title: "Permission Needed",
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))
        
        // display alert
        self.present(alertController, animated: true, completion: nil)
    }
}
