//
//  ProgressCell.swift
//  MultiVideoDownloadManager
//
//  Created by yilmaz on 27.12.2022.
//

import UIKit

protocol ProgressCellDelegate: AnyObject {
    func resume(name: String)
    func pause(name: String)
}

class ProgressCell: UITableViewCell {
    
    @IBOutlet weak var downloadView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var pauseButton: UIButton! {
        willSet {
            newValue.setImage(UIImage(systemName: "pause.circle"), for: .normal)
            newValue.setImage(UIImage(systemName: "play.circle"), for: .selected)
        }
    }
    
    private var name = ""
    
    weak var delegate: ProgressCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        downloadView.layer.masksToBounds = true
        downloadView.clipsToBounds = true
        downloadView.layer.cornerRadius = 5.0
        
        downloadView.image = UIImage(systemName: "icloud.and.arrow.down.fill")
    }
    
    func configure(name: String) {
        titleLabel?.text = name
        self.name = name
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
    
    @IBAction func pauseButtonAction(_ sender: UIButton) {
        if sender.isSelected {
            delegate?.resume(name: name)
        } else {
            delegate?.pause(name: name)
        }
        sender.isSelected.toggle()
    }
}

fileprivate extension UIImage {
    static func randomImage(seed: Int) -> UIImage {
        let images = (1...20).map { UIImage(named: "\($0)")! }
        return images[seed % images.count]
    }
}
