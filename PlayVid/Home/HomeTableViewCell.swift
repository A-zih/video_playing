//
//  HomeTableViewCell.swift
//  PlayVid
//
//  Created by 陳冠志 on 2024/6/24.
//

import UIKit

class HomeTableViewCell: UITableViewCell {
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var urlLabel: UILabel!
    
    private var videoData:Video = Video(title: "", url: "", duration: "")
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(with data: Video) {
        self.videoData = data
        setupUI()
    }
    
    func setupUI() {
        self.backgroundColor = .clear
        
        self.backView.backgroundColor = .white
        self.backView.layer.cornerRadius = 15
        
        self.imgView.layer.cornerRadius = 5
        
        self.titleLabel.text = videoData.title
        self.durationLabel.text = videoData.duration
        self.urlLabel.text = videoData.url
    }
}
