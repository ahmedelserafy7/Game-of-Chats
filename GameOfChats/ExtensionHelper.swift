//
//  ExtensionHelper.swift
//  GameOfChats
//
//  Created by Ahmed.S.Elserafy on 1/7/18.
//  Copyright © 2018 Ahmed.S.Elserafy. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat) {
        self.init(red: r/255, green: g/255, blue: b/255, alpha: 1)
    }
}

let imageCache = NSCache<NSString, UIImage>()

class CustomImageView: UIImageView {
    
    var imageUrlString: String?
    
    func loadProfileImagesInCacheWithURL(_ urlString: String) {
        
        imageUrlString = urlString
        
        self.image = nil
        // image in cache now
        if let imageFromCache = imageCache.object(forKey: urlString as NSString) {
            self.image = imageFromCache
            return
        }
        // image still loading...
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
            if error != nil {
                print(error!)
                // to return out of downloading image (not to complete), if it gets error
                return
            }
            
            guard let data = data else { return }
            DispatchQueue.main.async(execute: {
                let imageToCache = UIImage(data: data)
                
                if self.imageUrlString == urlString {
                    self.image = imageToCache
                }
                imageCache.setObject(imageToCache!, forKey: urlString as NSString)
                
            })
            
        }).resume()
    }
    
}
