//
//  ANIContributionVideoCell.swift
//  Ani
//
//  Created by jeonminseop on 2018/12/19.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import TinyConstraints
import Gallery

protocol ANIContributionVideoCellDelegate {
  func deleteButtonTapped()
}

class ANIContributionVideoCell: UICollectionViewCell {
  
  weak var coverImageView: UIImageView?
  weak var bottomAreaBackGroundView: UIView?
  private weak var videoIconImageView: UIImageView?
  weak var videoLengthLabel: UILabel?
  weak var deleteButton: UIButton?
  
  var delegate: ANIContributionVideoCellDelegate?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    //coverImageView
    let coverImageView = UIImageView()
    coverImageView.layer.cornerRadius = 10.0
    coverImageView.layer.masksToBounds = true
    coverImageView.backgroundColor = ANIColor.bg
    coverImageView.contentMode = .scaleAspectFill
    addSubview(coverImageView)
    coverImageView.edgesToSuperview()
    self.coverImageView = coverImageView
    
    //bottomAreaBackGroundView
    let bottomAreaBackGroundView = UIView()
    bottomAreaBackGroundView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, a: 0.5)
    coverImageView.addSubview(bottomAreaBackGroundView)
    bottomAreaBackGroundView.edgesToSuperview(excluding: .top)
    bottomAreaBackGroundView.height(30.0)
    self.bottomAreaBackGroundView = bottomAreaBackGroundView
    
    //videoIconImageView
    let videoIconImageView = UIImageView()
    videoIconImageView.contentMode = .scaleAspectFit
    videoIconImageView.image = UIImage(named: "videoIcon")
    bottomAreaBackGroundView.addSubview(videoIconImageView)
    videoIconImageView.leftToSuperview(offset: 10.0)
    videoIconImageView.centerYToSuperview()
    videoIconImageView.width(20.0)
    videoIconImageView.height(15.0)
    self.videoIconImageView = videoIconImageView
    
    //videoLengthLabel
    let videoLengthLabel = UILabel()
    videoLengthLabel.textColor = .white
    videoLengthLabel.font = UIFont.systemFont(ofSize: 15.0)
    bottomAreaBackGroundView.addSubview(videoLengthLabel)
    videoLengthLabel.centerYToSuperview()
    videoLengthLabel.rightToSuperview(offset: -10.0)
    self.videoLengthLabel = videoLengthLabel
    
    //deleteButton
    let deleteButton = UIButton()
    deleteButton.setImage(UIImage(named: "imageDeleteButton"), for: .normal)
    deleteButton.addTarget(self, action: #selector(videoDelegate), for: .touchUpInside)
    addSubview(deleteButton)
    deleteButton.width(30.0)
    deleteButton.height(30.0)
    deleteButton.top(to: coverImageView, offset: 10.0)
    deleteButton.right(to: coverImageView, offset: -10.0)
    self.deleteButton = deleteButton
  }
  
  @objc private func videoDelegate() {
    self.delegate?.deleteButtonTapped()
  }
}
