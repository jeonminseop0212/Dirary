//
//  ANICommunityMenuBar.swift
//  Ani
//
//  Created by 전민섭 on 2018/04/08.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import TinyConstraints

enum MenuKind {
  case noti;
  case message;
}

class ANiNotiMenuBar: UIView {
  weak var menuCollectionView: UICollectionView?
  private let menus = ["通知", "メッセージ"]
  var horizontalBarleftConstraint:Constraint?
  var notiViewController: ANINotiViewController?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    //menuCollectionView
    self.backgroundColor = .white
    let flowlayout = UICollectionViewFlowLayout()
    let collectionView = UICollectionView(frame: self.frame, collectionViewLayout: flowlayout)
    let id = NSStringFromClass(ANINotiMenuBarCell.self)
    collectionView.register(ANINotiMenuBarCell.self, forCellWithReuseIdentifier: id)
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.backgroundColor = .white
    let selectedIndexPath = IndexPath(item: 0, section: 0)
    collectionView.selectItem(at: selectedIndexPath, animated: false, scrollPosition: .left)
    addSubview(collectionView)
    collectionView.topToSuperview(offset: UIViewController.STATUS_BAR_HEIGHT)
    collectionView.leftToSuperview()
    collectionView.rightToSuperview()
    collectionView.height(ANICommunityViewController.NAVIGATION_BAR_HEIGHT)
    self.menuCollectionView = collectionView
    
    //horizontalBar
    let horizontalBar = UIView()
    horizontalBar.backgroundColor = ANIColor.emerald
    addSubview(horizontalBar)
    horizontalBarleftConstraint = horizontalBar.leftToSuperview()
    horizontalBar.widthToSuperview(multiplier: 1/2)
    horizontalBar.height(2.0)
    horizontalBar.bottomToSuperview()
  }
}

extension ANiNotiMenuBar: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return menus.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let id = NSStringFromClass(ANINotiMenuBarCell.self)
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! ANINotiMenuBarCell

    if indexPath.row == 0 {
      cell.menuKind = .noti
      if ANISessionManager.shared.isHaveUnreadNoti {
        cell.badge?.alpha = 1.0
      } else {
        cell.badge?.alpha = 0.0
      }
    } else if indexPath.row == 1 {
      cell.menuKind = .message
      if ANISessionManager.shared.isHaveUnreadMessage {
        cell.badge?.alpha = 1.0
      } else {
        cell.badge?.alpha = 0.0
      }
    }
    cell.menuLabel?.text = menus[indexPath.item]
    
    return cell
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let size = CGSize(width: collectionView.frame.width / 2, height: collectionView.frame.height)
    return size
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
    return 0
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard let notiViewController = self.notiViewController else { return }
    notiViewController.scrollToMenuIndex(menuIndex: indexPath.item)
  }
}

