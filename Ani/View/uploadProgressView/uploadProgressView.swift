//
//  ANIUploadProgressView.swift
//  Ani
//
//  Created by jeonminseop on 2018/12/23.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

protocol ANIUploadProgressViewDelegate {
  func completeProgress()
}

class ANIUploadProgressView: UIView {
  
  private weak var stackView: UIStackView?
  weak var thumbnailImageView: UIImageView?
  private weak var textLabel: UILabel?
  private weak var progressView: UIProgressView?
  
  var delegate: ANIUploadProgressViewDelegate?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    self.backgroundColor = .white
    
    //stackView
    let stackView = UIStackView()
    stackView.axis = .horizontal
    stackView.distribution = .fill
    stackView.spacing = 10
    addSubview(stackView)
    stackView.leftToSuperview(offset: 10.0)
    stackView.rightToSuperview(offset: -10.0)
    stackView.centerYToSuperview()
    self.stackView = stackView
    
    //thumbnailImageView
    let thumbnailImageView = UIImageView()
    thumbnailImageView.backgroundColor = ANIColor.bg
    thumbnailImageView.contentMode = .scaleAspectFill
    thumbnailImageView.layer.masksToBounds = true
    thumbnailImageView.alpha = 0.8
    stackView.addArrangedSubview(thumbnailImageView)
    thumbnailImageView.width(30.0)
    thumbnailImageView.height(30.0)
    self.thumbnailImageView = thumbnailImageView
    
    //textLabel
    let textLabel = UILabel()
    textLabel.textColor = ANIColor.darkGray
    textLabel.font = UIFont.systemFont(ofSize: 13.0)
    textLabel.text = "投稿中です..."
    textLabel.alpha = 0.95
    stackView.addArrangedSubview(textLabel)
    self.textLabel = textLabel
    
    //progressView
    let progressView = UIProgressView()
    progressView.progressViewStyle = .bar
    progressView.trackTintColor = ANIColor.bg
    progressView.progressTintColor = ANIColor.emerald
    progressView.alpha = 0.7
    addSubview(progressView)
    progressView.edgesToSuperview(excluding: .top)
    progressView.height(2)
    self.progressView = progressView
  }
  
  func updateProgress(progress: CGFloat) {
    guard let progressView = self.progressView else { return }
    
    progressView.progress = Float(progress)
    UIView.animate(withDuration: 0.1, animations: progressView.layoutIfNeeded) { (complete) in
      if progress == 1.0 {
        self.delegate?.completeProgress()
      }
    }
  }
}
