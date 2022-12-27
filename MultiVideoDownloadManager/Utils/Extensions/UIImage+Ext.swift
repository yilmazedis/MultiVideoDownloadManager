//
//  UIImage+Ext.swift
//  MultiVideoDownloadManager
//
//  Created by yilmaz on 27.12.2022.
//

import AVKit

extension UIImageView {
    func videoSnapshot(filePathLocal: String) {
        let vidURL = URL(fileURLWithPath:filePathLocal as String)
        let asset = AVURLAsset(url: vidURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        let timestamp = CMTime(seconds: 1, preferredTimescale: 60)
        
        do {
            let imageRef = try generator.copyCGImage(at: timestamp, actualTime: nil)
            self.image = UIImage(cgImage: imageRef)
        } catch let error as NSError {
            print("Image generation failed with error \(error)")
        }
    }
    
    func createVideoThumbnail(url: String?) {
        guard let url = URL(string: url ?? "") else { return }
        DispatchQueue.global().async {
            
            let url = url as URL
            let request = URLRequest(url: url)
            let cache = URLCache.shared
            
            if let cachedResponse = cache.cachedResponse(for: request),
               let image = UIImage(data: cachedResponse.data) {
                DispatchQueue.main.async {
                    self.image = image
                }
            }
            
            let asset = AVAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            
            var time = asset.duration
            time.value = min(time.value, 2)
            
            var image: UIImage?
            
            do {
                let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                image = UIImage(cgImage: cgImage)
            } catch {
                print("Remote image doesn't load with \(url)")
            }
            
            if
                let image = image,
                let data = image.pngData(),
                let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
            {
                let cachedResponse = CachedURLResponse(response: response, data: data)
                
                cache.storeCachedResponse(cachedResponse, for: request)
            }
            
            DispatchQueue.main.async {
                self.image = image
                //completion(image)
            }
        }
    }
}
