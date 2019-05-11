//
//  ANIImageFilterView.swift
//  Ani
//
//  Created by jeonminseop on 2018/05/11.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

protocol ANIImageFilterViewDelegate {
  func selectedFilter(filter: ANIFilter, selectedFilterIndex: Int)
}

class ANIImageFilterView: UIView {
  
  private weak var filtersCollectionView: UICollectionView?
  
  private let filterPreviews = ["Normal",
                                "Mono",
                                "Tonal",
                                "Noir",
                                "Fade",
                                "Chrome",
                                "Process",
                                "Transfer",
                                "Instant",
                                "Sepia"]
  private let filterNames = [
    "",
    "CIPhotoEffectMono",
    "CIPhotoEffectTonal",
    "CIPhotoEffectNoir",
    "CIPhotoEffectFade",
    "CIPhotoEffectChrome",
    "CIPhotoEffectProcess",
    "CIPhotoEffectTransfer",
    "CIPhotoEffectInstant",
    "CISepiaTone"
  ]
  private var filters = [ANIFilter]()
  private var filtersImages = [UIImage]()
  
  var selectedItemFilterIndex = Int() {
    didSet {
      guard let filtersCollectionView = self.filtersCollectionView else { return }
      let index = IndexPath(item: selectedItemFilterIndex, section: 0)
      filtersCollectionView.selectItem(at: index, animated: false, scrollPosition: .top)
    }
  }
  
  var delegate: ANIImageFilterViewDelegate?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setup()
    setupFilters()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    //filtersCollectionView
    let flowLayout = UICollectionViewFlowLayout()
    flowLayout.scrollDirection = .horizontal
    flowLayout.minimumInteritemSpacing = 0.0
    flowLayout.minimumLineSpacing = 0.0
    let filtersCollectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
    filtersCollectionView.backgroundColor = .white
    filtersCollectionView.showsHorizontalScrollIndicator = false
    filtersCollectionView.dataSource = self
    filtersCollectionView.delegate = self
    let id = NSStringFromClass(ANIImageFilterCell.self)
    filtersCollectionView.register(ANIImageFilterCell.self, forCellWithReuseIdentifier: id)
    let selectedIndexPath = IndexPath(item: 0, section: 0)
    filtersCollectionView.selectItem(at: selectedIndexPath, animated: false, scrollPosition: .left)
    addSubview(filtersCollectionView)
    filtersCollectionView.edgesToSuperview()
    self.filtersCollectionView = filtersCollectionView
  }
  
  private func setupFilters() {
    for filterName in filterNames {
      filters.append(ANIFilter(filterName))
    }
  }
}

extension ANIImageFilterView: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return filterNames.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let id = NSStringFromClass(ANIImageFilterCell.self)
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! ANIImageFilterCell
    cell.filterNameLabel?.text = filterPreviews[indexPath.row]
    let filter = self.filters[indexPath.row]
    let filteredImage = filter.filter(UIImage(named: "filterImage")!)
    cell.filterImageView?.image = filteredImage
    return cell
  }
}

extension ANIImageFilterView: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    self.delegate?.selectedFilter(filter: filters[indexPath.item], selectedFilterIndex: indexPath.item)
  }
}

extension ANIImageFilterView: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let width = ANIImageFilterCell.FILTER_IMAGE_VIEW_WIDTH + 4.0
    let height = collectionView.frame.height
    return CGSize(width: width, height: height)
  }
}
