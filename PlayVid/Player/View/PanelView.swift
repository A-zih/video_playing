//
//  PanelView.swift
//  PlayVid
//
//  Created by Zih on 2024/6/23.
//

import UIKit
import SnapKit

let iconConfig = UIImage.SymbolConfiguration(pointSize: 26, weight: .medium, scale: .default)

enum PlayType:Int {
    case Pause
    case Play
    case Forward
    case Backward
}

protocol PanelViewDelegate: AnyObject {
    func play()
    func pause()
    func goForward()
    func goBackward()
    func setRepeat(value: Bool)
    func changedSliderValue(value: Float)
    func showFullScreen(value: Bool)
    func adjustSpeed()
}

class PanelView: UIView {
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var backwardBtn: UIButton!
    @IBOutlet weak var forwardBtn: UIButton!
    @IBOutlet weak var fullScreenBtn: UIButton!
    @IBOutlet weak var repeatBtn: UIButton!
    @IBOutlet weak var speedBtn: UIButton!
    @IBOutlet weak var bufferProgress: UIProgressView!
    var currentType:PlayType = .Pause
    var isRepeatOn:Bool = false
    var isFullScreen:Bool = false
    weak var delegate:PanelViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        loadXib()
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadXib()
        setupUI()
    }
    
    func loadXib() {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "PanelView", bundle: bundle)
        guard let xibView = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }
        self.addSubview(xibView)
        self.backgroundColor = .clear
        xibView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)
        xibView.snp.makeConstraints{ make in
            make.top.left.bottom.right.equalTo(self)
        }
    }
    
    func setupUI() {
        func setupTimeLabel() {
            timeLabel.font = timeLabel.font?.withSize(15)
            timeLabel.textColor = .white
            timeLabel.text = "00:00 / 00:00"
        }
        func setupPlayBtn() {
            playBtn.setImage(UIImage(systemName: "play.fill", withConfiguration: iconConfig), for: .normal)
            playBtn.tintColor = .white
            playBtn.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        }
        func setupForwardBtn() {
            forwardBtn.tag = PlayType.Forward.rawValue
            forwardBtn.setImage(UIImage(systemName: "goforward.10", withConfiguration: iconConfig), for: .normal)
            forwardBtn.tintColor = .white
            forwardBtn.addTarget(self, action: #selector(goForwardOrBackward(_:)), for: .touchUpInside)
        }
        func setupBackwardBtn() {
            backwardBtn.tag = PlayType.Backward.rawValue
            backwardBtn.setImage(UIImage(systemName: "gobackward.10", withConfiguration: iconConfig), for: .normal)
            backwardBtn.tintColor = .white
            backwardBtn.addTarget(self, action: #selector(goForwardOrBackward(_:)), for: .touchUpInside)
        }
        func setupProgress() {
            bufferProgress.trackTintColor = .lightGray
            bufferProgress.progressTintColor = .white
        }
        func setupSlider() {
            let thumbImageNormal = UIImage(systemName: "circle.fill")?.withTintColor(.orange, renderingMode: .alwaysOriginal)
            slider.setThumbImage(thumbImageNormal, for: .normal)
            slider.bounds.size = CGSize(width: 18, height: 18)
            slider.tintColor = .orange
            slider.maximumTrackTintColor = .clear
            slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
            slider.addTarget(self, action: #selector(sliderTouchDown(_:)), for: .touchDown)
            slider.addTarget(self, action: #selector(sliderTouchUp(_:)), for: [.touchUpInside, .touchUpOutside])
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(sliderTapped(_:)))
            slider.addGestureRecognizer(tapGesture)
        }
        func setupRepeatBtn() {
            repeatBtn.setImage(UIImage(systemName: "repeat"), for: .normal)
            repeatBtn.tintColor = .lightGray
            repeatBtn.addTarget(self, action: #selector(didTapRepeat), for: .touchUpInside)
        }
        func setupFullScreenBtn() {
            if let flipImg = Utils.flipIcon(iconName: "arrow.up.left.and.arrow.down.right") {
                fullScreenBtn.setImage(flipImg, for: .normal)
            }
            fullScreenBtn.tintColor = .white
            fullScreenBtn.addTarget(self, action: #selector(didTapFullScreen), for: .touchUpInside)
        }
        func setupSpeedBtn() {
            speedBtn.tintColor = .white
            speedBtn.addTarget(self, action: #selector(didTapSpeed), for: .touchUpInside)
        }
    
        setupTimeLabel()
        setupPlayBtn()
        setupForwardBtn()
        setupBackwardBtn()
        setupProgress()
        setupSlider()
        setupRepeatBtn()
        setupFullScreenBtn()
        setupSpeedBtn()
    }
    
    func setFinished() {
        playBtn.setImage(UIImage(systemName: "play.fill", withConfiguration: iconConfig), for: .normal)
        currentType = .Pause
    }
    
    func setIsFullScreen(value: Bool) {
        isFullScreen = value
        if let flipImg = Utils.flipIcon(iconName: value ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right") {
            fullScreenBtn.setImage(flipImg, for: .normal)
        }
    }
    
    @objc func playTapped() {
        switch currentType {
        case .Pause:
            playBtn.setImage(UIImage(systemName: "pause.fill", withConfiguration: iconConfig), for: .normal)
            currentType = .Play
            delegate?.play()
        case .Play:
            playBtn.setImage(UIImage(systemName: "play.fill", withConfiguration: iconConfig), for: .normal)
            currentType = .Pause
            delegate?.pause()
        case .Forward, .Backward:
            break
        }
    }
    
    @objc private func goForwardOrBackward(_ sender:UIButton) {
        switch sender.tag {
        case PlayType.Forward.rawValue:
            delegate?.goForward()
        case PlayType.Backward.rawValue:
            delegate?.goBackward()
        default:
            break
        }
    }
    
    @objc private func didTapRepeat() {
        isRepeatOn.toggle()
        repeatBtn.tintColor = isRepeatOn ? .white : .lightGray
        delegate?.setRepeat(value: isRepeatOn)
    }
    
    @objc private func didTapFullScreen() {
        delegate?.showFullScreen(value: isFullScreen)
    }
    
    @objc private func didTapSpeed() {
        delegate?.adjustSpeed()
    }

    @objc private func sliderValueChanged(_ sender: UISlider) {
        delegate?.changedSliderValue(value: sender.value)
    }
    
    @objc private func sliderTouchDown(_ sender: UISlider) {
        delegate?.pause()
    }
        
    @objc private func sliderTouchUp(_ sender: UISlider) {
        if currentType == .Play {
            delegate?.play()
        }
    }
    
    @objc func sliderTapped(_ gesture: UITapGestureRecognizer) {
        if gesture.state == .ended {
            let point = gesture.location(in: slider)
            let width = slider.frame.size.width - slider.currentThumbImage!.size.width
            let newValue = (point.x / width) * CGFloat(slider.maximumValue - slider.minimumValue)
            slider.setValue(Float(newValue + CGFloat(slider.minimumValue)), animated: true)
            delegate?.changedSliderValue(value: slider.value)
        }
    }
}
