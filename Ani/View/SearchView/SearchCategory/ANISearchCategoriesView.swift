//
//  ANISearchCategoriesView.swift
//  Ani
//
//  Created by 전민섭 on 2018/04/16.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import TinyConstraints

protocol ANISearchCategoriesViewDelegate {
  func didSelectedCell(index: Int)
}

class ANISearchCategoriesView: UIView {
  
  weak var categoryCollectionView: UICollectionView?
  
  private var category = [SearchCategory.user.rawValue, SearchCategory.qna.rawValue]
  
  var delegate: ANISearchCategoriesViewDelegate?
  
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
    flowlayout.scrollDirection = .horizontal
    flowlayout.sectionInset = UIEdgeInsets(top: -2, left: 12, bottom: 0, right: 12)
    let collectionView = UICollectionView(frame: self.frame, collectionViewLayout: flowlayout)
    let id = NSStringFromClass(ANISearchCategoryCell.self)
    collectionView.register(ANISearchCategoryCell.self, forCellWithReuseIdentifier: id)
    collectionView.backgroundColor = .white
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.alwaysBounceHorizontal = true
    collectionView.dataSource = self
    collectionView.delegate = self
    let selectedIndexPath = IndexPath(item: 0, section: 0)
    collectionView.selectItem(at: selectedIndexPath, animated: false, scrollPosition: .left)
    addSubview(collectionView)
    collectionView.edgesToSuperview()
    self.categoryCollectionView = collectionView
  }
}

//MARK: UICollectionViewDataSource
extension ANISearchCategoriesView: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return category.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let id = NSStringFromClass(ANISearchCategoryCell.self)
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! ANISearchCategoryCell
    
    cell.categoryLabel?.text = category[indexPath.item]
    
    return cell
  }
}

//MARK: UICollectionViewDelegateFlowLayout
extension ANISearchCategoriesView: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let size = ANISearchCategoryCell.sizeWithCategory(category: category[indexPath.item])
    return size
  }
}

//MARK: UICollectionViewDelegate
extension ANISearchCategoriesView: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    self.delegate?.didSelectedCell(index: indexPath.item)
  }
}
