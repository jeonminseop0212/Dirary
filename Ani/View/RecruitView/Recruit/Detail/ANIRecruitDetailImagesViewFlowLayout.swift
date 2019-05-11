//
//  ANIRecruitDetailImagesViewFlowLayout.swift
//  Ani
//
//  Created by jeonminseop on 2018/04/28.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

protocol ANIRecruitDetailImagesViewFlowLayoutDelegate: class {
  func collectionView(collectionView: UICollectionView, widthForPhotoAt indexPath: IndexPath, with height: CGFloat) -> CGFloat
}

class ANIRecruitDetailImagesViewFlowLayout: UICollectionViewLayout {
  
  var delegate: ANIRecruitDetailImagesViewFlowLayoutDelegate?
  
  var numberOfLines: CGFloat = 1
  var cellPadding: CGFloat = 2.0
  
  private var contentWidth: CGFloat = 0.0
  private var contentHeight: CGFloat {
    let insets = collectionView!.contentInset
    return (collectionView!.bounds.height - (insets.top + insets.bottom))
  }
  private var attributesCache = [ANIRecruitDetailImagesViewFlowLayoutAttributes]()
  
  override func prepare() {
    
    attributesCache.removeAll()
    let lineheight = contentHeight / numberOfLines
    var yOffsets = [CGFloat]()
    for line in 0 ..< Int(numberOfLines) {
      yOffsets.append(CGFloat(line) * lineheight)
    }
    
    var line = 0
    var xOffsets = [CGFloat](repeating: 0, count: Int(numberOfLines))
    
    contentWidth = 0.0
    
    for item in 0 ..< collectionView!.numberOfItems(inSection: 0) {
      let height = lineheight - cellPadding * 2
      
      let indexPath = IndexPath(item: item, section: 0)
      let photoWidth: CGFloat = (delegate?.collectionView(collectionView: collectionView!, widthForPhotoAt: indexPath, with: height))!
      
      let width: CGFloat = cellPadding + photoWidth + cellPadding
      let frame = CGRect(x: xOffsets[line], y: yOffsets[line], width: width, height: lineheight)
      let insetFrame = frame.insetBy(dx: cellPadding, dy: cellPadding)
      
      let attributes = ANIRecruitDetailImagesViewFlowLayoutAttributes(forCellWith: indexPath)
      attributes.photoWidth = photoWidth
      attributes.frame = insetFrame
      attributesCache.append(attributes)
      contentWidth = contentWidth + width
      xOffsets[line] = xOffsets[line] + width
      
      if line >= (Int(numberOfLines) - 1) {
        line = 0
      } else {
        line = line + 1
      }
    }
  }
  
  override var collectionViewContentSize: CGSize {
    return CGSize(width: contentWidth, height: contentHeight)
  }
  
  override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    var layoutAttributes = [UICollectionViewLayoutAttributes]()
    
    for attributes in attributesCache {
      if attributes.frame.intersects(rect) {
        layoutAttributes.append(attributes)
      }
    }
    
    return layoutAttributes
  }
}

class ANIRecruitDetailImagesViewFlowLayoutAttributes: UICollectionViewLayoutAttributes {
  var photoWidth: CGFloat = 0.0
  
  override func copy(with zone: NSZone? = nil) -> Any {
    let copy = super.copy(with: zone) as! ANIRecruitDetailImagesViewFlowLayoutAttributes
    copy.photoWidth = photoWidth
    return copy
  }
  
  override func isEqual(_ object: Any?) -> Bool {
    if let attributes = object as? ANIRecruitDetailImagesViewFlowLayoutAttributes {
      if attributes.photoWidth == photoWidth {
        return super.isEqual(object)
      }
    }
    
    return false
  }
}
