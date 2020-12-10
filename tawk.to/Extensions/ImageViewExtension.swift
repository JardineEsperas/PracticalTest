//
//  ImageViewExtension.swift
//  tawk.to
//
//  Created by Marc Jardine Esperas on 12/8/20.
//

import UIKit

let imageCache = NSCache<NSString, UIImage>()

extension UIImageView {
    
    func loadImage(_ urlString: String, isInverted: Bool) {

        self.image = nil

        if let cachedImage = imageCache.object(forKey: NSString(string: urlString)) {
            self.image = cachedImage
            return
        }

        if let url = URL(string: urlString) {

            URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                
                if error != nil {

                    print("ERROR LOADING IMAGES FROM URL")

                    return

                }

                DispatchQueue.main.async {

                    if let data = data {

                        if var downloadedImage = UIImage(data: data) {

                            if isInverted {
                                downloadedImage = self.invertImage(image: downloadedImage)
                            }
                            
                            imageCache.setObject(downloadedImage, forKey: NSString(string: urlString))
                            
                            self.image = downloadedImage

                        }

                    }

                }

            }).resume()

        }

    }
    
    func invertImage (image: UIImage) -> UIImage {
        
        if let filter = CIFilter(name: "CIColorInvert"), let ciimage = CIImage(image: image) {
            
            filter.setValue(ciimage, forKey: kCIInputImageKey)
            
            return UIImage(ciImage: filter.outputImage!)
            
        }
        
        return image
    }

}
