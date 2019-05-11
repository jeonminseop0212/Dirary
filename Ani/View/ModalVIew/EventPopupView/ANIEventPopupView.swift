//
//  ANIEventPopupView.swift
//  Ani
//
//  Created by jeonminseop on 2019/01/29.
//  Copyright © 2019 JeonMinseop. All rights reserved.
//

import UIKit

protocol ANIEventPopupViewDelegate {
  func showDetail()
}

class ANIEventPopupView: UIView {
  
  private weak var imageView: UIImageView?
  
  private weak var stackView: UIStackView?
  private weak var titleLabel: UILabel?
  private weak var subtitleLabel: UILabel?
  private weak var dateLabel: UILabel?
  private weak var detailLabel: UILabel?
  
  var event: FirebaseEvent? {
    didSet {
      reloadLayout()
    }
  }
  
  var delegate: ANIEventPopupViewDelegate?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    self.backgroundColor = .white
    
    //imageView
    let imageView = UIImageView()
    imageView.backgroundColor = ANIColor.bg
    imageView.contentMode = .scaleAspectFill
    imageView.layer.masksToBounds = true
    addSubview(imageView)
    imageView.edgesToSuperview(excluding: .bottom)
    imageView.heightToWidth(of: imageView)
    self.imageView = imageView
    
    //stackView
    let stackView = UIStackView()
    stackView.axis = .vertical
    stackView.distribution = .equalSpacing
    stackView.spacing = 10.0
    addSubview(stackView)
    stackView.topToBottom(of: imageView, offset: 10.0)
    stackView.leftToSuperview(offset: 10.0)
    stackView.rightToSuperview(offset: -10.0)
    stackView.bottomToSuperview(offset: -10.0)
    self.stackView = stackView
    
    //titleLabel
    let titleLabel = UILabel()
    titleLabel.numberOfLines = 0
    titleLabel.textColor = ANIColor.dark
    titleLabel.font = UIFont.boldSystemFont(ofSize: 16.0)
    titleLabel.textAlignment = .center
    stackView.addArrangedSubview(titleLabel)
    self.titleLabel = titleLabel
    
    //subtitleLabel
    let subtitleLabel = UILabel()
    subtitleLabel.numberOfLines = 0
    subtitleLabel.textColor = ANIColor.subTitle
    subtitleLabel.font = UIFont.systemFont(ofSize: 15.0)
    subtitleLabel.textAlignment = .center
    stackView.addArrangedSubview(subtitleLabel)
    self.subtitleLabel = subtitleLabel
    
    //dateLabel
    let dateLabel = UILabel()
    dateLabel.numberOfLines = 0
    dateLabel.textColor = ANIColor.darkGray
    dateLabel.font = UIFont.systemFont(ofSize: 13.0)
    dateLabel.text = "期限：2019.1.1~2019.2.3"
    dateLabel.textAlignment = .center
    stackView.addArrangedSubview(dateLabel)
    self.dateLabel = dateLabel
    
    //detailLabel
    let detailLabel = UILabel()
    let text = "詳しくはこちら！"
    detailLabel.font = UIFont.systemFont(ofSize: 12.0)
    detailLabel.textColor = ANIColor.darkGray
    detailLabel.text = text
    detailLabel.textAlignment = .center
    detailLabel.isUserInteractionEnabled = true
    detailLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showDetail)))
    let textRange = NSMakeRange(0, text.count)
    let attributedText = NSMutableAttributedString(string: text)
    attributedText.addAttribute(NSAttributedString.Key.underlineStyle , value: NSUnderlineStyle.single.rawValue, range: textRange)
    detailLabel.attributedText = attributedText
    stackView.addArrangedSubview(detailLabel)
    self.detailLabel = detailLabel
  }
  
  private func reloadLayout() {
    guard let imageView = self.imageView,
          let titleLabel = self.titleLabel,
          let subtitleLabel = self.subtitleLabel,
          let dateLabel = self.dateLabel,
          let event = self.event,
          let imageUrl = event.imageUrl,
          let date = event.date else { return }
    
    imageView.sd_setImage(with: URL(string: imageUrl), completed: nil)
    titleLabel.text = event.title
    subtitleLabel.text = event.subtitle?.replacingOccurrences(of: "\\n", with: "\n")
    dateLabel.text = date
  }
  
  @objc private func showDetail() {
    self.delegate?.showDetail()
  }
}
