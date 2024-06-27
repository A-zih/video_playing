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
    private lazy var dismissBtn: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(systemName: "xmark", withConfiguration: iconConfig), for: .normal)
        btn.tintColor = .white
        return btn
    }()
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    private lazy var panelView: PanelView = {
        let panelView = PanelView()
        panelView.delegate = self
        return panelView
    }()
    private lazy var errorView: ErrorView = {
        let errorView = ErrorView()
        return errorView
    }()
    private lazy var loadingView: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .white
        activityIndicator.hidesWhenStopped = true
        return activityIndicator
    }()
    private var isSeeking:Bool = false
    private var shouldUpdateLayout = true
    private var shouldRepeat = false
    private var currentSpeed:Float = 1.0
    private var observerStatus: NSKeyValueObservation?
    private var playbackBufferEmptyObserver: NSKeyValueObservation?
    private var playbackLikelyToKeepUpObserver: NSKeyValueObservation?
    private var loadedTimeRangesObserver: NSKeyValueObservation?
    var playerURL:String
    var hideControlsTimer: Timer?
    var player: AVPlayer!
    var playerItem: AVPlayerItem!
    var playerLayer: AVPlayerLayer!
    var timeObserverToken: Any?
    
    init(url: String) {
        self.playerURL = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        addAllObservers()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if shouldUpdateLayout {
            self.updateLayout()
            shouldUpdateLayout = false
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] context in
            guard let self = self else { return }
            self.updateLayout()
        }, completion: nil)
    }
    
    deinit {
        hideControlsTimer?.invalidate()
        removeAllObservers()
    }
    
    func setupUI() {
        func setupBackground() {
            self.view.backgroundColor = .black.withAlphaComponent(0.95)
        }
        
        func setupDismissBtn() {
            self.view.addSubview(dismissBtn)
            dismissBtn.snp.makeConstraints { make in
                make.top.left.equalTo(self.view.safeAreaLayoutGuide).offset(15)
                make.width.height.equalTo(30)
            }
            dismissBtn.addTarget(self, action: #selector(didTapDismiss), for: .touchUpInside)
        }
        
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
            guard let url = URL(string: self.playerURL) else { fatalError("Invalid URL") }
            playerItem = AVPlayerItem(url: url)
            player = AVPlayer(playerItem: playerItem)
            playerLayer = AVPlayerLayer(player: self.player)
            playerLayer.videoGravity = .resizeAspectFill
            playerLayer.frame = self.containerView.bounds
            self.containerView.layer.addSublayer(playerLayer)
        }
        
        func setupLoadingView() {
            self.containerView.addSubview(loadingView)
            loadingView.snp.makeConstraints { make in
                make.center.equalTo(self.containerView)
            }
            loadingView.startAnimating()
        }
        
        setupBackground()
        setupDismissBtn()
        setupContainerView()
        setupPlayerView()
        setupLoadingView()
    }
    
    func addAllObservers() {
        //addPeriodicTimeObserver
        let interval = CMTime(seconds: 1, preferredTimescale: 1)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self, !self.isSeeking else { return }
            let currentTime = CMTimeGetSeconds(time)
            let duration = CMTimeGetSeconds(self.player.currentItem?.duration ?? CMTime(value: 1, timescale: 1))
            let progress = Float(currentTime / duration)
            self.panelView.slider.value = progress
            self.panelView.timeLabel.text = Utils.convertSecondToTimeString(seconds: Int(currentTime)) + " / " + Utils.convertSecondToTimeString(seconds: Int(duration))
        }
        //Observe status
        observerStatus = playerItem.observe(\.status, changeHandler: { [weak self] (item, value) in
            guard let self = self else { return }
            switch item.status {
            case .readyToPlay:
                debugPrint("status: ready to play")
                self.readyToPlayAndSetupPanelView()
            case .unknown, .failed:
                debugPrint("status: failed ", item.error as Any)
                self.failToPlayAndSetupErrorView()
            @unknown default:
                debugPrint("status: failed ", item.error as Any)
                self.failToPlayAndSetupErrorView()
            }
        })
        // Observe playbackBufferEmpty
        playbackBufferEmptyObserver = playerItem.observe(\.isPlaybackBufferEmpty) { [weak self] (item, value) in
            guard let self = self else { return }
            if item.isPlaybackBufferEmpty {
                self.loadingView.startAnimating()
            }
        }
        // Observe playbackLikelyToKeepUp
        playbackLikelyToKeepUpObserver = playerItem.observe(\.isPlaybackLikelyToKeepUp) { [weak self] (item, value) in
            guard let self = self else { return }
            if item.isPlaybackLikelyToKeepUp {
                if self.panelView.currentType == .Play {
                    self.loadingView.stopAnimating()
                }
            }
        }
        // Observe loaded buffer
        loadedTimeRangesObserver = playerItem.observe(\.loadedTimeRanges, options: [.new]) { [weak self] (item, value) in
            guard let self = self else { return }
            let loadedTimeRanges = item.loadedTimeRanges
            guard let timeRange = loadedTimeRanges.first?.timeRangeValue else { return }
            let startSeconds = CMTimeGetSeconds(timeRange.start)
            let durationSeconds = CMTimeGetSeconds(timeRange.duration)
            let totalBuffer = startSeconds + durationSeconds
            if let currentItem = self.player.currentItem {
                let duration = CMTimeGetSeconds(currentItem.asset.duration)
                self.panelView.bufferProgress.progress = Float(totalBuffer / duration)
            }
        }
        NotificationCenter.default.addObserver(self, selector:#selector(playerDidFinishPlaying),name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    func removeAllObservers() {
        NotificationCenter.default.removeObserver(self)
        if let token = timeObserverToken {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }
        observerStatus?.invalidate()
        playbackBufferEmptyObserver?.invalidate()
        playbackLikelyToKeepUpObserver?.invalidate()
        loadedTimeRangesObserver?.invalidate()
    }
    
    func readyToPlayAndSetupPanelView() {
        self.loadingView.stopAnimating()
        if let currentItem = self.player.currentItem {
            let duration = CMTimeGetSeconds(currentItem.asset.duration)
            self.containerView.addSubview(self.panelView)
            self.panelView.snp.makeConstraints { make in
                make.top.bottom.left.right.equalTo(self.containerView)
            }
            self.panelView.timeLabel.text = "00:00 / " + Utils.convertSecondToTimeString(seconds: Int(duration))
        }
        self.panelView.playTapped()
    }
    
    func failToPlayAndSetupErrorView() {
        self.loadingView.stopAnimating()
        self.containerView.addSubview(self.errorView)
        self.errorView.snp.makeConstraints { make in
            make.top.bottom.left.right.equalTo(self.containerView)
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
    
    private func updateLayout() {
        guard let windowScene = self.view.window?.windowScene else { return }
        panelView.setIsFullScreen(value: windowScene.interfaceOrientation.isLandscape)
        dismissBtn.isHidden = windowScene.interfaceOrientation.isLandscape
        if UIDevice.current.userInterfaceIdiom == .phone {
            if windowScene.interfaceOrientation.isLandscape {
                containerView.snp.remakeConstraints { make in
                    make.center.equalTo(self.view)
                    make.height.equalTo(self.view).multipliedBy(1)
                    make.width.equalTo(containerView.snp.height).multipliedBy(16.0/9.0)
                }
            } else if windowScene.interfaceOrientation.isPortrait {
                containerView.snp.remakeConstraints { make in
                    make.center.equalTo(self.view)
                    make.width.equalTo(self.view).multipliedBy(1)
                    make.height.equalTo(containerView.snp.width).multipliedBy(9.0/16.0)
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.playerLayer.frame = self.containerView.bounds
        }
        self.view.layoutIfNeeded()
    }
    
    private func startHidePanelViewTimer() {
        hideControlsTimer?.invalidate()
        hideControlsTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.panelView.isHidden = true
        }
    }
    
    @objc private func didTapOnPlayerView() {
        panelView.isHidden.toggle()
        if !panelView.isHidden && panelView.currentType != .Pause {
            startHidePanelViewTimer()
        }
    }
    
    @objc private func didTapDismiss() {
        self.dismiss(animated: false)
    }
    
    @objc private func playerDidFinishPlaying() {
        if shouldRepeat {
            seekToTime(seconds: 0)
            player.play()
        } else {
            player.pause()
            panelView.setFinished()
        }
    }
    
    @objc private func applicationDidEnterBackground() {
        if panelView.currentType == .Play {
            panelView.playTapped()
        }
    }
}

extension PlayerViewController: PanelViewDelegate {
    func play() {
        player.play()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.player.rate = self.currentSpeed
        }
        startHidePanelViewTimer()
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
            guard let windowScene = self.view.window?.windowScene else { return }
            if windowScene.interfaceOrientation.isPortrait {
                let ori = UIInterfaceOrientation.landscapeRight.rawValue
                UIDevice.current.setValue(ori, forKey: "orientation")
            } else {
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
        
        //for ipad
        if let popoverPresentationController = alert.popoverPresentationController {
            popoverPresentationController.sourceView = view
            popoverPresentationController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popoverPresentationController.permittedArrowDirections = []
        }
        
        self.present(alert, animated: true)
    }
}
