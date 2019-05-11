//
//  ANIProfileMenuBar.swift
//  Ani
//
//  Created by 전민섭 on 2018/04/17.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

protocol ANIProfileMenuBarDelegate {
  func didSelecteMenuItem(selectedIndex: Int)
}

class ANIProfileMenuBar: UIView {
  
  var delegate: ANIProfileMenuBarDelegate?

  weak var menuCollectionView: UICollectionView?
  private let menus = ["プロフィール", "ストーリー", "Q&A", "募集"]
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    self.backgroundColor = .white
    let flowlayout = UICollectionViewFlowLayout()
    let collectionView = UICollectionView(frame: self.frame, collectionViewLayout: flowlayout)
    let id = NSStringFromClass(ANIProfileMenuBarCell.self)
    collectionView.register(ANIProfileMenuBarCell.self, forCellWithReuseIdentifier: id)
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.backgroundColor = ANIColor.gray
    let selectedIndexPath = IndexPath(item: 0, section: 0)
    collectionView.selectItem(at: selectedIndexPath, animated: false, scrollPosition: .left)
    addSubview(collectionView)
    collectionView.edgesToSuperview()
    self.menuCollectionView = collectionView
  }
}

//MAKR: UICollectionViewDataSource
extension ANIProfileMenuBar: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return 4
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let id = NSStringFromClass(ANIProfileMenuBarCell.self)
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! ANIProfileMenuBarCell
    cell.menuLabel?.text = menus[indexPath.item]
    return cell
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
    return 0
  }
}

//MARK: UICollectionViewDelegateFlowLayout
extension ANIProfileMenuBar: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let size = CGSize(width: collectionView.frame.width / 4, height: collectionView.frame.height)
    return size
  }
}

//MARK: UICollectionViewDelegate
extension ANIProfileMenuBar: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    self.delegate?.didSelecteMenuItem(selectedIndex: indexPath.item)
  }
}
