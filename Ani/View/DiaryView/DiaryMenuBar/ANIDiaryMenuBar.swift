//
//  ANICommunityMenuBar.swift
//  Ani
//
//  Created by 전민섭 on 2018/04/08.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import TinyConstraints

protocol ANIDiaryMenuBarDelegate {
  func didSelectCell(index: IndexPath)
}

class ANIDiaryMenuBar: UIView {
  weak var menuCollectionView: UICollectionView?
  var horizontalBarBaseleftConstraint: Constraint?
  
  var delegate: ANIDiaryMenuBarDelegate?
    
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
    let id = NSStringFromClass(ANIDiaryMenuBarCell.self)
    collectionView.register(ANIDiaryMenuBarCell.self, forCellWithReuseIdentifier: id)
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.backgroundColor = .white
    let selectedIndexPath = IndexPath(item: 0, section: 0)
    collectionView.selectItem(at: selectedIndexPath, animated: false, scrollPosition: .left)
    addSubview(collectionView)
    collectionView.topToSuperview(offset: UIViewController.STATUS_BAR_HEIGHT)
    collectionView.leftToSuperview()
    collectionView.rightToSuperview()
    collectionView.height(UIViewController.NAVIGATION_BAR_HEIGHT)
    self.menuCollectionView = collectionView
    
    //horizontalBar
    let horizontalBarBase = UIView()
    addSubview(horizontalBarBase)
    horizontalBarBaseleftConstraint = horizontalBarBase.leftToSuperview()
    horizontalBarBase.widthToSuperview(multiplier: 1/2)
    horizontalBarBase.height(2.0)
    horizontalBarBase.bottomToSuperview()
    
    //horizontalBar
    let horizontalBar = UIView()
    horizontalBar.backgroundColor = ANIColor.dark
    horizontalBarBase.addSubview(horizontalBar)
    horizontalBar.width(50.0)
    horizontalBar.height(2.0)
    horizontalBar.centerInSuperview()
  }
}

//MARK: UICollectionViewDataSource
extension ANIDiaryMenuBar: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return 2
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let id = NSStringFromClass(ANIDiaryMenuBarCell.self)
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! ANIDiaryMenuBarCell
    
    if indexPath.item == 0 {
      cell.menuImageView?.image = UIImage(named: "tableTab")
    } else {
      cell.menuImageView?.image = UIImage(named: "collectionTab")
    }
    
    return cell
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
    return 0
  }
}

//MAKR: UICollectionViewDelegateFlowLayout
extension ANIDiaryMenuBar: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let size = CGSize(width: collectionView.frame.width / 2, height: collectionView.frame.height)
    return size
  }
}

//MARK: UICollectionViewDelegate
extension ANIDiaryMenuBar: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    self.delegate?.didSelectCell(index: indexPath)
  }
}
