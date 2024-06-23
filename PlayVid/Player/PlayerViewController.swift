//
//  PlayerViewController.swift
//  PlayVid
//
//  Created by Zih on 2024/6/21.
//

import UIKit
import AVKit
import SnapKit

let iconConfig = UIImage.SymbolConfiguration(pointSize: 26, weight: .medium, scale: .default)

enum PlayType:Int {
    case Pause
    case Play
    case Forward
    case Backward
}

class PlayerViewController: UIViewController {
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    private lazy var controlView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        return view
    }()
    private lazy var slider:UISlider = {
        let slider = UISlider()
        let thumbImageNormal = UIImage(systemName: "circle.fill")?.withTintColor(.orange, renderingMode: .alwaysOriginal)
        slider.setThumbImage(thumbImageNormal, for: .normal)
        let thumbSize = CGSize(width: 18, height: 18)
        slider.bounds.size = thumbSize
        slider.tintColor = .orange
        slider.maximumTrackTintColor = .lightGray
        return slider
    }()
    private lazy var forwardBtn:UIButton = {
        let btn = UIButton()
        btn.tag = PlayType.Forward.rawValue
        btn.setImage(UIImage(systemName: "goforward.10", withConfiguration: iconConfig), for: .normal)
        btn.tintColor = .white
        return btn
    }()
    private lazy var backwardBtn:UIButton = {
        let btn = UIButton()
        btn.tag = PlayType.Backward.rawValue
        btn.setImage(UIImage(systemName: "gobackward.10", withConfiguration: iconConfig), for: .normal)
        btn.tintColor = .white
        return btn
    }()
    private lazy var playBtn:UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(systemName: "play.fill", withConfiguration: iconConfig), for: .normal)
        btn.tintColor = .white
        return btn
    }()
    private lazy var timeLabel:UILabel = {
        let label = UILabel()
        label.font = label.font.withSize(15)
        label.textColor = UIColor(red: 152, green: 155, blue: 163, alpha: 1)
        label.text = "00:00 / 00:00"
        return label
    }()
    private var currentType:PlayType = .Pause
    private var isSeeking:Bool = false
    private var shouldUpdateLayout = true
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
        
        func setupControlView() {
            self.containerView.addSubview(controlView)
            controlView.snp.makeConstraints { make in
                make.top.bottom.left.right.equalTo(self.containerView)
            }
            
            self.controlView.addSubview(slider)
            slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
            slider.addTarget(self, action: #selector(sliderTouchDown(_:)), for: .touchDown)
            slider.addTarget(self, action: #selector(sliderTouchUp(_:)), for: [.touchUpInside, .touchUpOutside])
            slider.snp.makeConstraints { make in
                make.height.equalTo(20)
                make.bottom.equalTo(self.controlView.safeAreaLayoutGuide)
                make.left.right.equalTo(self.controlView.safeAreaLayoutGuide)
            }
            
            self.controlView.addSubview(timeLabel)
            timeLabel.snp.makeConstraints { make in
                make.bottom.equalTo(slider.snp.top).offset(-5)
                make.left.equalTo(slider.snp.left).offset(8)
            }
            if let currentItem = self.player.currentItem {
                let duration = CMTimeGetSeconds(currentItem.asset.duration)
                timeLabel.text = "00:00 / " + Utils.convertSecondToTimeString(seconds: Int(duration))
            }
            
            playBtn.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
            self.controlView.addSubview(playBtn)
            playBtn.snp.makeConstraints { make in
                make.height.width.equalTo(50)
                make.centerX.equalTo(self.controlView.snp.centerX)
                make.centerY.equalTo(self.controlView.snp.centerY)
            }
            
            backwardBtn.addTarget(self, action: #selector(goForwardOrBackward(_:)), for: .touchUpInside)
            self.controlView.addSubview(backwardBtn)
            backwardBtn.snp.makeConstraints { make in
                make.height.width.equalTo(50)
                make.right.equalTo(playBtn.snp.left).offset(-30)
                make.top.equalTo(playBtn.snp.top)
            }
            
            forwardBtn.addTarget(self, action: #selector(goForwardOrBackward(_:)), for: .touchUpInside)
            self.controlView.addSubview(forwardBtn)
            forwardBtn.snp.makeConstraints { make in
                make.height.width.equalTo(50)
                make.left.equalTo(playBtn.snp.right).offset(30)
                make.top.equalTo(playBtn.snp.top)
            }
        }
        
        setupContainerView()
        setupPlayerView()
        setupControlView()
    }
    
    @objc private func playTapped() {
        switch currentType {
        case .Pause:
            player.play()
//            player.rate = currentSpeed
            playBtn.setImage(UIImage(systemName: "pause.fill", withConfiguration: iconConfig), for: .normal)
            currentType = .Play
//            startHideControlsTimer()
        case .Play:
            player.pause()
            playBtn.setImage(UIImage(systemName: "play.fill", withConfiguration: iconConfig), for: .normal)
            currentType = .Pause
            hideControlsTimer?.invalidate()
        case .Forward, .Backward:
            break
        }
    }
    
    @objc func sliderValueChanged(_ sender: UISlider) {
        if let currentItem = player.currentItem {
            let totalSeconds = CMTimeGetSeconds(currentItem.duration)
            let currentSeconds = Float64(sender.value) * totalSeconds
            seekToTime(seconds: currentSeconds)
        }
    }
    
    @objc func sliderTouchDown(_ sender: UISlider) {
        player.pause()
    }
        
    @objc func sliderTouchUp(_ sender: UISlider) {
        if currentType == .Play {
            player.play()
        }
    }
    
    func addPeriodicTimeObserver() {
        let interval = CMTime(seconds: 1, preferredTimescale: 1)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self, !self.isSeeking else { return }
            let currentTime = CMTimeGetSeconds(time)
            let duration = CMTimeGetSeconds(self.player.currentItem?.duration ?? CMTime(value: 1, timescale: 1))
            let progress = Float(currentTime / duration)
            self.slider.value = progress
            self.timeLabel.text = Utils.convertSecondToTimeString(seconds: Int(currentTime)) + " / " + Utils.convertSecondToTimeString(seconds: Int(duration))
        }
    }
    
    @objc private func didTapOnPlayerView() {
        controlView.isHidden.toggle()
//        if !controlView.isHidden && currentType != .Pause {
//            startHideControlsTimer()
//        }
    }
    
    private func startHideControlsTimer() {
        hideControlsTimer?.invalidate()
        hideControlsTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(hideControls), userInfo: nil, repeats: false)
    }
    
    @objc private func hideControls() {
        controlView.isHidden = true
    }
    
    @objc private func goForwardOrBackward(_ sender:UIButton) {
        
        var current = CMTimeGetSeconds(player.currentTime())
        
        switch sender.tag {
        case PlayType.Forward.rawValue:
            current += 10
        case PlayType.Backward.rawValue:
            current -= 10
        default:
            break
        }
        seekToTime(seconds: current)
    }
    
    private func seekToTime(seconds: Float64) {
        isSeeking = true
        if let currentItem = player.currentItem {
            let totalSeconds = CMTimeGetSeconds(currentItem.duration)
            let clampedSeconds = max(0, min(seconds, totalSeconds))
            self.timeLabel.text = Utils.convertSecondToTimeString(seconds: Int(clampedSeconds)) + " / " + Utils.convertSecondToTimeString(seconds: Int(totalSeconds))
            let progress = Float(clampedSeconds / totalSeconds)
            self.slider.value = progress
        }
        
        player.seek(to: CMTimeMakeWithSeconds(seconds, preferredTimescale: 600)) { [weak self] done in
            guard let self = self else { return }
            if done {
                self.isSeeking = false
            }
        }
    }
    
    @objc func playerDidFinishPlaying() {
        player.pause()
        playBtn.setImage(UIImage(systemName: "play.fill", withConfiguration: iconConfig), for: .normal)
        currentType = .Pause
    }
    
    private func updateLayout() {
        let newOrientation = UIDevice.current.orientation
        if newOrientation.isLandscape {
            containerView.snp.remakeConstraints { make in
                make.center.equalTo(self.view)
                make.height.equalTo(self.view).multipliedBy(1)
                make.width.equalTo(containerView.snp.height).multipliedBy(16.0/9.0)
            }
        } else if newOrientation.isPortrait {
            containerView.snp.remakeConstraints { make in
                make.center.equalTo(self.view)
                make.width.equalTo(self.view).multipliedBy(1)
                make.height.equalTo(containerView.snp.width).multipliedBy(9.0/16.0)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.playerLayer.frame = self.controlView.bounds
        }
        self.view.layoutIfNeeded()
    }
}
