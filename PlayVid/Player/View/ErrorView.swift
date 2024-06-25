//
//  ErrorView.swift
//  PlayVid
//
//  Created by 陳冠志 on 2024/6/25.
//

import UIKit

class ErrorView: UIView {
    @IBOutlet weak var errorImage: UIImageView!
    @IBOutlet weak var errorLabel: UILabel!
    
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
        let nib = UINib(nibName: "ErrorView", bundle: bundle)
        guard let xibView = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }
        self.addSubview(xibView)
        self.backgroundColor = .clear
        xibView.snp.makeConstraints{ make in
            make.top.left.bottom.right.equalTo(self)
        }
    }
    
    func setupUI() {
        func setupErrorImage() {
            errorImage.image = UIImage(systemName: "exclamationmark.octagon.fill", withConfiguration: iconConfig)
        }
        
        setupErrorImage()
    }
}
