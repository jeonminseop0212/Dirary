//
//  ANIRecruitViewCell.swift
//  Ani
//
//  Created by 전민섭 on 2018/04/06.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

class ANICommunityStoryCell: UICollectionViewCell {
  private weak var storyView: ANIStoryView?
  
  var isCellSelected: Bool = false {
    didSet {
      guard let storyView = self.storyView else { return }
      
      storyView.isCellSelected = isCellSelected
    }
  }
  
  var delegate: ANIStoryViewDelegate? {
    get { return self.storyView?.delegate }
    set(v) { self.storyView?.delegate = v }
  }
  
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    let storyView = ANIStoryView()
    ANIStoryView.shared = storyView
    addSubview(storyView)
    storyView.edgesToSuperview()
    self.storyView = storyView
  }
  
  func playVideo() {
    guard let storyView = self.storyView else { return }
    
    storyView.playVideo()
  }
  
  func stopVideo() {
    guard let storyView = self.storyView else { return }
    
    storyView.stopVideo()
  }
}
