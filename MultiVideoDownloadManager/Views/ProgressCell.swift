//
//  ProgressCell.swift
//  MultiVideoDownloadManager
//
//  Created by yilmaz on 27.12.2022.
//

import UIKit

class ProgressCell: UITableViewCell {
    
    @IBOutlet weak var downloadView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        downloadView.layer.masksToBounds = true
        downloadView.clipsToBounds = true
        downloadView.layer.cornerRadius = 5.0
        
        downloadView.image = UIImage(systemName: "icloud.and.arrow.down.fill")
    }
    
    func configure(name: String) {
        titleLabel?.text = name
    }
    
    func updateProgressBar(at progress: Double) {
        progressBar.isHidden = false
        progressBar.progress = Float(progress)
        subtitleLabel.isHidden = false
        subtitleLabel.text = "\(String(format: "%.2f", progress * 100))%"
        downloadView.isHidden = false
    }
    
    func completeProgressBar(at index: Int) {
        progressBar.isHidden = true
        subtitleLabel.isHidden = true
        downloadView.isHidden = false
        downloadView.image = UIImage(systemName: "photo.on.rectangle.angled")
        //downloadView.createVideoThumbnail(url: K.urls[index])
    }
}

fileprivate extension UIImage {
    static func randomImage(seed: Int) -> UIImage {
        let images = (1...20).map { UIImage(named: "\($0)")! }
        return images[seed % images.count]
    }
}
