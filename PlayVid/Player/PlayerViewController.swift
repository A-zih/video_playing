//
//  PlayerViewController.swift
//  PlayVid
//
//  Created by Zih on 2024/6/21.
//

import UIKit
import AVKit
import SnapKit

class PlayerViewController: UIViewController {
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    private lazy var panelView: PanelView = {
        let panelView = PanelView()
        panelView.delegate = self
        return panelView
    }()
    private var isSeeking:Bool = false
    private var shouldUpdateLayout = true
    private var shouldRepeat = false
    private var currentSpeed:Float = 1.0
    var hideControlsTimer: Timer?
    var player: AVPlayer!
    var playerLayer: AVPlayerLayer!
    var timeObserverToken: Any?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        addPeriodicTimeObserver()
        NotificationCenter.default.addObserver(self, selector:#selector(playerDidFinishPlaying),name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        if let token = timeObserverToken {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }
        hideControlsTimer?.invalidate()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if shouldUpdateLayout {
            self.updateLayout()
            shouldUpdateLayout = false
        }
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        coordinator.animate(alongsideTransition: { context in
            self.shouldUpdateLayout = true
        }, completion: nil)
    }
    
    func setupUI() {
        func setupContainerView() {
            self.view.addSubview(containerView)
            containerView.snp.makeConstraints { make in
                make.center.equalTo(self.view)
                make.width.equalTo(self.view).multipliedBy(1)
                make.height.equalTo(containerView.snp.width).multipliedBy(9.0/16.0)
            }
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapOnPlayerView))
            containerView.addGestureRecognizer(tapGestureRecognizer)
        }
        
        func setupPlayerView() {
            guard let url = URL(string: "https://videos.pexels.com/video-files/5207408/5207408-hd_1920_1080_25fps.mp4") else {
                return
            }
            player = AVPlayer(url: url)
            playerLayer = AVPlayerLayer(player: player)
            playerLayer.videoGravity = .resizeAspectFill
            playerLayer.frame = self.containerView.bounds
            self.containerView.layer.addSublayer(playerLayer)
        }
                
        func setupPanelView() {
            self.containerView.addSubview(panelView)
            panelView.snp.makeConstraints { make in
                make.top.bottom.left.right.equalTo(self.containerView)
            }
            if let currentItem = self.player.currentItem {
                let duration = CMTimeGetSeconds(currentItem.asset.duration)
                panelView.timeLabel.text = "00:00 / " + Utils.convertSecondToTimeString(seconds: Int(duration))
            }
        }
        
        setupContainerView()
        setupPlayerView()
        setupPanelView()
    }
    
    func addPeriodicTimeObserver() {
        let interval = CMTime(seconds: 1, preferredTimescale: 1)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self, !self.isSeeking else { return }
            let currentTime = CMTimeGetSeconds(time)
            let duration = CMTimeGetSeconds(self.player.currentItem?.duration ?? CMTime(value: 1, timescale: 1))
            let progress = Float(currentTime / duration)
            self.panelView.slider.value = progress
            self.panelView.timeLabel.text = Utils.convertSecondToTimeString(seconds: Int(currentTime)) + " / " + Utils.convertSecondToTimeString(seconds: Int(duration))
        }
    }
    
    @objc private func didTapOnPlayerView() {
        panelView.isHidden.toggle()
        if !panelView.isHidden && panelView.currentType != .Pause {
            startHideControlsTimer()
        }
    }
    
    private func startHideControlsTimer() {
        hideControlsTimer?.invalidate()
        hideControlsTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.panelView.isHidden = true
        }
    }
        
    private func seekToTime(seconds: Float64) {
        isSeeking = true
        if let currentItem = player.currentItem {
            let totalSeconds = CMTimeGetSeconds(currentItem.duration)
            let clampedSeconds = max(0, min(seconds, totalSeconds))
            panelView.timeLabel.text = Utils.convertSecondToTimeString(seconds: Int(clampedSeconds)) + " / " + Utils.convertSecondToTimeString(seconds: Int(totalSeconds))
            let progress = Float(clampedSeconds / totalSeconds)
            panelView.slider.value = progress
        }
        
        player.seek(to: CMTimeMakeWithSeconds(seconds, preferredTimescale: 600)) { [weak self] done in
            guard let self = self else { return }
            if done {
                self.isSeeking = false
            }
        }
    }
    
    @objc func playerDidFinishPlaying() {
        if shouldRepeat {
            seekToTime(seconds: 0)
            player.play()
        } else {
            player.pause()
            panelView.setFinished()
        }
    }
    
    private func updateLayout() {
        guard let windowScene = self.view.window?.windowScene else { return }
        if windowScene.interfaceOrientation.isLandscape {
            panelView.setIsFullScreen(value: true)
            containerView.snp.remakeConstraints { make in
                make.center.equalTo(self.view)
                make.height.equalTo(self.view).multipliedBy(1)
                make.width.equalTo(containerView.snp.height).multipliedBy(16.0/9.0)
            }
        } else if windowScene.interfaceOrientation.isPortrait {
            panelView.setIsFullScreen(value: false)
            containerView.snp.remakeConstraints { make in
                make.center.equalTo(self.view)
                make.width.equalTo(self.view).multipliedBy(1)
                make.height.equalTo(containerView.snp.width).multipliedBy(9.0/16.0)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.playerLayer.frame = self.containerView.bounds
        }
        self.view.layoutIfNeeded()
    }
}

extension PlayerViewController: PanelViewDelegate {
    func play() {
        player.play()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.player.rate = self.currentSpeed
        }
        startHideControlsTimer()
    }
    
    func pause() {
        player.pause()
        hideControlsTimer?.invalidate()
    }
    
    func goForward() {
        var current = CMTimeGetSeconds(player.currentTime())
        current += 10
        seekToTime(seconds: current)
    }
    
    func goBackward() {
        var current = CMTimeGetSeconds(player.currentTime())
        current -= 10
        seekToTime(seconds: current)
    }
    
    func setRepeat(value: Bool) {
        shouldRepeat = value
    }
    
    func changedSliderValue(value: Float) {
        if let currentItem = player.currentItem {
            let totalSeconds = CMTimeGetSeconds(currentItem.duration)
            let currentSeconds = Float64(value) * totalSeconds
            seekToTime(seconds: currentSeconds)
        }
    }
    
    func showFullScreen(value: Bool) {
        if #available(iOS 16.0, *) {
            guard let windowScene = self.view.window?.windowScene else { return }
            if windowScene.interfaceOrientation.isPortrait {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
            } else {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            }
        } else {
            if UIDevice.current.orientation.isPortrait && value {
                let ori = UIInterfaceOrientation.landscapeRight.rawValue
                UIDevice.current.setValue(ori, forKey: "orientation")
            } else if UIDevice.current.orientation.isLandscape && !value {
                let ori = UIInterfaceOrientation.portrait.rawValue
                UIDevice.current.setValue(ori, forKey: "orientation")
            }
        }
    }
    
    func adjustSpeed() {
        let alert = UIAlertController(title: "播放速度", message: nil, preferredStyle: .actionSheet)
        let speeds:[Float] = [0.5, 1.0, 1.5, 2.0]
        for speed in speeds {
            let action = UIAlertAction(title: String(speed) + "x", style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.currentSpeed = speed
                if self.panelView.currentType == .Play {
                    self.player.rate = speed
                }
                let formattedSpeed = speed.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", speed) : String(speed)
                let boldFont = UIFont.boldSystemFont(ofSize: self.panelView.speedBtn.titleLabel?.font.pointSize ?? 17)
                let attributes: [NSAttributedString.Key: Any] = [.font: boldFont]
                let attributedTitle = NSAttributedString(string: formattedSpeed + "x", attributes: attributes)
                self.panelView.speedBtn.setAttributedTitle(attributedTitle, for: .normal)
            }
            alert.addAction(action)
        }
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true)
    }
}
