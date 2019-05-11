//
//  ANIContributionImagesCell.swift
//  Ani
//
//  Created by jeonminseop on 2018/05/17.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

protocol ANIContributionImagesCellDelegate {
  func deleteButtonTapped(index: Int)
}

class ANIContributionImagesCell: UICollectionViewCell {
  
  weak var imageView: UIImageView?
  weak var deleteButton: UIButton?
  
  var delegate: ANIContributionImagesCellDelegate?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    //imageView
    let imageView = UIImageView()
    imageView.backgroundColor = ANIColor.bg
    imageView.layer.cornerRadius = 10.0
    imageView.layer.masksToBounds = true
    imageView.contentMode = .scaleAspectFill
    addSubview(imageView)
    imageView.edgesToSuperview()
    self.imageView = imageView
    
    //deleteButton
    let deleteButton = UIButton()
    deleteButton.setImage(UIImage(named: "imageDeleteButton"), for: .normal)
    deleteButton.addTarget(self, action: #selector(imageDelegate), for: .touchUpInside)
    addSubview(deleteButton)
    deleteButton.width(30.0)
    deleteButton.height(30.0)
    deleteButton.top(to: imageView, offset: 10.0)
    deleteButton.right(to: imageView, offset: -10.0)
    self.deleteButton = deleteButton
  }
  
  @objc private func imageDelegate() {
    guard let deleteButton = self.deleteButton else { return }
    self.delegate?.deleteButtonTapped(index: deleteButton.tag)
  }
}
