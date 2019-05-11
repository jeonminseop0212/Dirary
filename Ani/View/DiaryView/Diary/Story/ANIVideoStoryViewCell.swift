//
//  ANIVideoStoryViewCell.swift
//  Ani
//
//  Created by jeonminseop on 2018/12/20.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import FirebaseFirestore
import CodableFirebase
import AVKit
import ActiveLabel
import TinyConstraints

protocol ANIVideoStoryViewCellDelegate {
  func storyCellTapped(story: FirebaseStory, user: FirebaseUser)
  func reject()
  func popupOptionView(isMe: Bool, contentType: ContentType, id: String)
  func loadedStoryIsLoved(indexPath: Int, isLoved: Bool)
  func loadedStoryUser(user: FirebaseUser)
  func loadedVideo(urlString: String, asset: AVAsset)
}

class ANIVideoStoryViewCell: UITableViewCell {
  
  private weak var stackView: UIStackView?
  weak var storyVideoView: ANIStoryVideoView?
  private weak var storyLabelBase: UIView?
  private weak var storyLabel: ActiveLabel?
  
  var story: FirebaseStory?

  var videoAsset: AVAsset?
  
  var indexPath: Int?
  
  var delegate: ANIVideoStoryViewCellDelegate?
  
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
    
    //storyVideoView
    let storyVideoView = ANIStoryVideoView()
    storyVideoView.backgroundColor = ANIColor.gray
    storyVideoView.removeReachEndObserver()
    storyVideoView.delegate = self
    stackView.addArrangedSubview(storyVideoView)
    storyVideoView.edgesToSuperview(excluding: .bottom)
    storyVideoView.height(UIScreen.main.bounds.width, priority: .defaultHigh)
    self.storyVideoView = storyVideoView
    
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
    storyLabel.topToSuperview(offset: 10.0)
    storyLabel.leftToSuperview(offset: 10.0)
    storyLabel.rightToSuperview(offset: -10.0, priority: .defaultHigh)
    storyLabel.bottomToSuperview()
    self.storyLabel = storyLabel
  }
  
  private func reloadLayout() {
    guard let storyVideoView = self.storyVideoView,
          let storyLabelBase = self.storyLabelBase,
          let storyLabel = self.storyLabel,
          let story = self.story else { return }
    
    if let storyVideoUrl = story.storyVideoUrl,
      let videoUrl = URL(string: storyVideoUrl),
      let thumbnailImageUrl = story.thumbnailImageUrl,
      let imageUrl = URL(string: thumbnailImageUrl) {
      storyVideoView.setPreviewImage(imageUrl)
      
      storyVideoView.videoAsset = videoAsset
      storyVideoView.loadVideo(videoUrl)
      storyVideoView.addReachEndObserver()
      
      if let indexPath = self.indexPath,
        indexPath == 0 {
        storyVideoView.play()
      }
    }
    
    storyLabel.text = story.story
    if story.story == "" {
      storyLabelBase.isHidden = true
    } else {
      storyLabelBase.isHidden = false
    }
  }
}

//MARK: ANIVideoViewDelegate
extension ANIVideoStoryViewCell: ANIStoryVideoViewDelegate {
  func loadedVideo(urlString: String, asset: AVAsset) {
    self.delegate?.loadedVideo(urlString: urlString, asset: asset)
  }
}
