//
//  ANIRecruitViewCell.swift
//  Ani
//
//  Created by 전민섭 on 2018/04/06.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import FirebaseFirestore
import CodableFirebase
import StoreKit
import ActiveLabel
import TinyConstraints

protocol ANIStoryViewCellDelegate {
  func storyCellTapped(story: FirebaseStory, user: FirebaseUser)
  func reject()
  func popupOptionView(isMe: Bool, contentType: ContentType, id: String)
  func loadedStoryIsLoved(indexPath: Int, isLoved: Bool)
  func loadedStoryUser(user: FirebaseUser)
}

class ANIStoryViewCell: UITableViewCell {
  private weak var stackView: UIStackView?
  private weak var tapArea: UIView?
  private weak var storyImagesView: ANIStoryImagesView?
  private weak var storyLabelBase: UIView?
  private weak var storyLabel: ActiveLabel?
  
  var story: FirebaseStory?
  
  var indexPath: Int?
  
  var delegate: ANIStoryViewCellDelegate?
  
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    self.selectionStyle = .none
    self.backgroundColor = .white
    
    //stackView
    let stackView = UIStackView()
    stackView.axis = .vertical
    stackView.distribution = .equalSpacing
    stackView.spacing = 0.0
    addSubview(stackView)
    stackView.edgesToSuperview()
    self.stackView = stackView
    
    //tapArea
    let tapArea = UIView()
    stackView.addArrangedSubview(tapArea)
    self.tapArea = tapArea
    
    //storyImagesView
    let storyImagesView = ANIStoryImagesView()
    tapArea.addSubview(storyImagesView)
    storyImagesView.edgesToSuperview()
    self.storyImagesView = storyImagesView
    
    //storyLabelBase
    let storyLabelBase = UIView()
    storyLabelBase.backgroundColor = .white
    stackView.addArrangedSubview(storyLabelBase)
    self.storyLabelBase = storyLabelBase

    //storyLabel
    let storyLabel = ActiveLabel()
    storyLabel.font = UIFont.systemFont(ofSize: 14.0)
    storyLabel.textAlignment = .left
    storyLabel.textColor = ANIColor.subTitle
    storyLabel.numberOfLines = 0
    storyLabel.enabledTypes = [.hashtag]
    storyLabel.customize { (label) in
      label.hashtagColor = ANIColor.darkblue
    }
    storyLabel.handleHashtagTap { (hashtag) in
      ANINotificationManager.postTapHashtag(contributionKind: KEY_CONTRIBUTION_KIND_STROY, hashtag: hashtag)
    }
    storyLabelBase.addSubview(storyLabel)
    storyLabel.topToSuperview(offset: 5.0)
    storyLabel.leftToSuperview(offset: 10.0)
    storyLabel.rightToSuperview(offset: -10.0, priority: .defaultHigh)
    storyLabel.bottomToSuperview()
    self.storyLabel = storyLabel
  }
  
  private func reloadLayout() {
    guard let storyImagesView = self.storyImagesView,
          let storyLabelBase = self.storyLabelBase,
          let storyLabel = self.storyLabel,
          let story = self.story else { return }
    
    if let storyImageUrls = story.storyImageUrls {
      storyImagesView.imageUrls = storyImageUrls
      storyImagesView.pageControl?.numberOfPages = storyImageUrls.count
    }
    storyLabel.text = story.story

    if story.story == "" {
      storyLabelBase.isHidden = true
    } else {
      storyLabelBase.isHidden = false
    }
  }
}

