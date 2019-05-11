//
//  ANICommunityMenuBarCell.swift
//  Ani
//
//  Created by 전민섭 on 2018/04/08.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import TinyConstraints
import FirebaseFirestore

class ANINotiMenuBarCell: UICollectionViewCell {
  
  private let BADGE_WIDHT: CGFloat = 5.0
  weak var badge: UIView?
  
  var menuLabel: UILabel?
  var menuKind: MenuKind = .noti {
    didSet {
      setupNotifications()
    }
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override var isHighlighted: Bool {
    didSet {
      menuLabel?.textColor = isHighlighted ? ANIColor.dark : ANIColor.gray
    }
  }
  
  override var isSelected: Bool {
    didSet {
      menuLabel?.textColor = isSelected ? ANIColor.dark : ANIColor.gray
    }
  }
  
  private func setup() {
    //menuLabel
    let menuLabel = UILabel()
    menuLabel.textAlignment = .center
    menuLabel.font = UIFont.boldSystemFont(ofSize: 17)
    menuLabel.textColor = ANIColor.gray
    addSubview(menuLabel)
    menuLabel.centerInSuperview()
    self.menuLabel = menuLabel
    
    //badge
    let badge = UIView()
    badge.backgroundColor = ANIColor.red
    badge.layer.cornerRadius = BADGE_WIDHT / 2
    badge.layer.masksToBounds = true
    badge.alpha = 0.0
    addSubview(badge)
    badge.top(to: menuLabel, offset: -1.0)
    badge.right(to: menuLabel, offset: 6.0)
    badge.width(BADGE_WIDHT)
    badge.height(BADGE_WIDHT)
    self.badge = badge
  }
  
  private func setupNotifications() {
    if menuKind == .noti {
      ANINotificationManager.receive(changeIsHaveUnreadNoti: self, selector: #selector(updateNotiBadge))
    } else if menuKind == .message {
      ANINotificationManager.receive(changeIsHaveUnreadMessage: self, selector: #selector(updateMessageBadge))
    }
  }
  
  @objc private func updateNotiBadge() {
    guard let badge = self.badge else { return }
    
    if ANISessionManager.shared.isHaveUnreadNoti {
      badge.alpha = 1.0
    } else {
      badge.alpha = 0.0
    }
  }
  
  @objc private func updateMessageBadge() {
    guard let badge = self.badge else { return }
    
    if ANISessionManager.shared.isHaveUnreadMessage {
      badge.alpha = 1.0
    } else {
      badge.alpha = 0.0
    }
  }
}

