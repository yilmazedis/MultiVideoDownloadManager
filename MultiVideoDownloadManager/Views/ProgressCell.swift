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
    }
    
    func configure(_ task: DownloadTask, at index: Int) {
        titleLabel?.text = "\(task.state.description) #\(task.identifier)"
        downloadView.image = UIImage.randomImage(seed: Int(task.identifier) ?? 0)
        
        switch task.state {
        case .pending:
            progressBar.isHidden = true
            subtitleLabel.isHidden = true
            downloadView.isHidden = true
            
        case .inProgess(let complete):
            progressBar.isHidden = false
            progressBar.progress = Float(Double(complete)/100.0)
            subtitleLabel.isHidden = false
            subtitleLabel.text = "\(complete)%"
            downloadView.isHidden = false
            
        case .completed:
            progressBar.isHidden = true
            subtitleLabel.isHidden = true
            downloadView.isHidden = false
            self.downloadView.image = UIImage(systemName: "photo.on.rectangle.angled")
            downloadView.createVideoThumbnail(url: K.urls[index])
        }
    }
    
}

fileprivate extension UIImage {
    static func randomImage(seed: Int) -> UIImage {
        let images = (1...20).map { UIImage(named: "\($0)")! }
        return images[seed % images.count]
    }
}
