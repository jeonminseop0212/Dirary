//
//  ANIRecruitFiltersView.swift
//  Ani
//
//  Created by 전민섭 on 2018/04/05.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import TinyConstraints

protocol ANIRecruitFiltersViewDelegate {
  func didSelectedItem(index: Int)
}

class ANIRecruitFiltersView: UIView {
  
  weak var filterCollectionView: UICollectionView?
  
  private var filters = ["お家", "種類", "年齢", "性別"]
  
  var pickMode: FilterPickMode?
  var pickItem: String? {
    didSet {
      guard let pickMode = self.pickMode,
            let pickItem = self.pickItem,
            let filterCollectionView = self.filterCollectionView else { return }
      
      switch pickMode {
      case .home:
        if pickItem == "選択しない" || pickItem == "" {
          filters[0] = "お家"
        } else {
          filters[0] = pickItem
        }
      case .kind:
        if pickItem == "選択しない" || pickItem == "" {
          filters[1] = "種類"
        } else {
          filters[1] = pickItem
        }
      case .age:
        if pickItem == "選択しない" || pickItem == "" {
          filters[2] = "年齢"
        } else {
          filters[2] = pickItem
        }
      case .sex:
        if pickItem == "選択しない" || pickItem == "" {
          filters[3] = "性別"
        } else {
          filters[3] = pickItem
        }
      }
      
      filterCollectionView.reloadData()
    }
  }
  
  var delegate: ANIRecruitFiltersViewDelegate?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    self.backgroundColor = .white
    
    //collectionView
    let flowlayout = UICollectionViewFlowLayout()
    flowlayout.scrollDirection = .horizontal
    flowlayout.sectionInset = UIEdgeInsets(top: -2, left: 12, bottom: 0, right: 12)
    let collectionView = UICollectionView(frame: self.frame, collectionViewLayout: flowlayout)
    let id = NSStringFromClass(ANIRecruitFilterCell.self)
    collectionView.register(ANIRecruitFilterCell.self, forCellWithReuseIdentifier: id)
    collectionView.backgroundColor = .white
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.alwaysBounceHorizontal = true
    collectionView.dataSource = self
    collectionView.delegate = self
    addSubview(collectionView)
    collectionView.edgesToSuperview()
    self.filterCollectionView = collectionView
  }
}

//MARK: UICollectionViewDataSource
extension ANIRecruitFiltersView: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return filters.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let id = NSStringFromClass(ANIRecruitFilterCell.self)
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! ANIRecruitFilterCell
    
    cell.filter = filters[indexPath.item]
    
    return cell
  }
}

//MARK: UICollectionViewDelegateFlowLayout
extension ANIRecruitFiltersView: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    
    let size = ANIRecruitFilterCell.sizeWithFilter(filter: filters[indexPath.item])
    
    return size
  }
}

//MARK: UICollectionViewDelegate
extension ANIRecruitFiltersView: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    self.delegate?.didSelectedItem(index: indexPath.item)
  }
}
