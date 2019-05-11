//
//  ANIMyChatViewCell.swift
//  Ani
//
//  Created by jeonminseop on 2018/06/27.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

class ANIMyChatViewCell: UITableViewCell {
  
  private weak var stackView: UIStackView?
  private weak var dateLabelBG: UIView?
  private weak var dateLabel: UILabel?
  private weak var leftLine: UIView?
  private weak var rightLine: UIView?
  private weak var base: UIView?
  private weak var messageBG: UIView?
  private weak var messageLabel: UILabel?
  private weak var timeLabel: UILabel?
  
  var message: FirebaseChatMessage?
  
  var chagedDate: String? {
    didSet {
      reloadLayout()
    }
  }
  
  static let shared = ANIMyChatViewCell()
  
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    self.selectionStyle = .none
    
    //stackView
    let stackView = UIStackView()
    stackView.axis = .vertical
    stackView.distribution = .fill
    addSubview(stackView)
    stackView.edgesToSuperview()
    self.stackView = stackView
    
    //dateLabelBG
    let dateLabelBG = UIView()
    stackView.addArrangedSubview(dateLabelBG)
    dateLabelBG.height(30)
    self.dateLabelBG = dateLabelBG
    
    //dateLabel
    let dateLabel = UILabel()
    dateLabel.backgroundColor = .white
    dateLabel.textColor = ANIColor.moreDarkGray
    dateLabel.font = UIFont.systemFont(ofSize: 13)
    dateLabel.textAlignment = .center
    dateLabelBG.addSubview(dateLabel)
    dateLabel.centerXToSuperview()
    dateLabel.bottomToSuperview()
    self.dateLabel = dateLabel
    
    //leftLine
    let leftLine = UIView()
    leftLine.backgroundColor = ANIColor.darkGray
    dateLabelBG.addSubview(leftLine)
    leftLine.leftToSuperview(offset: 10)
    leftLine.rightToLeft(of: dateLabel, offset: -10)
    leftLine.centerY(to: dateLabel)
    leftLine.height(0.5)
    self.leftLine = leftLine
    
    //rightLine
    let rightLine = UIView()
    rightLine.backgroundColor = ANIColor.darkGray
    dateLabelBG.addSubview(rightLine)
    rightLine.leftToRight(of: dateLabel, offset: 10)
    rightLine.rightToSuperview(offset: -10)
    rightLine.centerY(to: dateLabel)
    rightLine.height(0.5)
    self.rightLine = rightLine
    
    //base
    let base = UIView()
    stackView.addArrangedSubview(base)
    self.base = base
    
    //messageBG
    let messageBG = UIView()
    messageBG.backgroundColor = ANIColor.moreDarkGray
    messageBG.layer.cornerRadius = 10.0
    messageBG.layer.masksToBounds = true
    base.addSubview(messageBG)
    let width = UIScreen.main.bounds.width * 0.7
    messageBG.topToSuperview(offset: 5.0)
    messageBG.rightToSuperview(offset: -10.0)
    messageBG.bottomToSuperview(offset: -5.0, priority: .defaultHigh)
    messageBG.width(min: 0.0, max: width)
    self.messageBG = messageBG

    //messageLabel
    let messageLabel = UILabel()
    messageLabel.font = UIFont.systemFont(ofSize: 15.0)
    messageLabel.textColor = .white
    messageLabel.numberOfLines = 0
    messageBG.addSubview(messageLabel)
    let labelInsets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    messageLabel.edgesToSuperview(insets: labelInsets)
    self.messageLabel = messageLabel
    
    //timeLabel
    let timeLabel = UILabel()
    timeLabel.textColor = ANIColor.darkGray
    timeLabel.font = UIFont.systemFont(ofSize: 11)
    base.addSubview(timeLabel)
    timeLabel.rightToLeft(of: messageBG, offset: -4.0)
    timeLabel.bottom(to: messageBG)
    self.timeLabel = timeLabel
  }
  
  private func reloadLayout() {
    guard let dateLabelBG = self.dateLabelBG,
          let dateLabel = self.dateLabel,
          let messageLabel = self.messageLabel,
          let message = self.message,
          let timeLabel = self.timeLabel  else { return }
    
    dateLabelBG.isHidden = true
    if let chagedDate = self.chagedDate {
      dateLabelBG.isHidden = false
      dateLabel.text = chagedDate
    } else {
      dateLabelBG.isHidden = true
    }
    
    messageLabel.text = message.message
    
    let currentDate = ANIFunction.shared.getCurrentLocaleDateFromString(string: message.date)
    let suffixString = String(currentDate.prefix(16))
    timeLabel.text = String(suffixString.suffix(5))
  }
}
