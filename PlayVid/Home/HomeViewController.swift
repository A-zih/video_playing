//
//  HomeViewController.swift
//  PlayVid
//
//  Created by 陳冠志 on 2024/6/24.
//

import UIKit

class HomeViewController: UIViewController {
    let samples = [
        Video(title: "範例影片1", url: "https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_2mb.mp4", duration: "00:13"),
        Video(title: "範例影片2", url: "https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_10mb.mp4", duration: "01:02"),
        Video(title: "範例影片3", url: "https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_20mb.mp4", duration: "01:57"),
        Video(title: "範例影片4", url: "https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_30mb.mp4", duration: "02:50"),
        Video(title: "範例影片5", url: "https://sample-videos.com/video321/mp4/240/big_buck_bunny_240p_30mb.mp4", duration: "06:08"),
        
        Video(title: "範例影片6", url: "https://videos.pexels.com/video-files/9953721/9953721-uhd_2560_1440_30fps.mp4", duration: "00:22"),
        Video(title: "錯誤範例7", url: "this is a wrong url", duration: "00:22"),
        Video(title: "範例影片8", url: "https://sample-videos.com/video321/mp4/480/big_buck_bunny_480p_30mb.mp4", duration: "03:03"),

    ]
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        tableView.register(UINib(nibName: "HomeTableViewCell", bundle: nil), forCellReuseIdentifier: "HomeListCell")
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
    }
    
    
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return samples.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 110
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HomeListCell", for: indexPath) as! HomeTableViewCell
        cell.selectionStyle = .none
        
        cell.configure(with: samples[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let playerVC = PlayerViewController(url: samples[indexPath.row].url)
        playerVC.modalPresentationStyle = .overCurrentContext
        self.present(playerVC, animated: false)
    }
}
