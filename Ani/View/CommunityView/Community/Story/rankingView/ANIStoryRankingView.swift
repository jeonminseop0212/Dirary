//
//  ANIStoryRankingView.swift
//  Ani
//
//  Created by jeonminseop on 2018/11/17.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

protocol ANIStoryRankingViewDelegate {
  func didSelectRankingCell(rankingStory: FirebaseStory, ranking: Int)
}

class ANIStoryRankingView: UIView {
  
  private weak var rankingColletionView: UICollectionView?
  
  var rankingStories = [FirebaseStory]() {
    didSet {
      guard let rankingColletionView = self.rankingColletionView else { return }
      
      rankingColletionView.reloadData()
    }
  }
  
  private var users = [FirebaseUser]()
  
  var delegate: ANIStoryRankingViewDelegate?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setup()
    setupNotifications()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {    
    //rankingColletionView
    let flowLayot = UICollectionViewFlowLayout()
    flowLayot.scrollDirection = .horizontal
    flowLayot.minimumLineSpacing = 10.0
    let rankingColletionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayot)
    rankingColletionView.contentInset = UIEdgeInsets(top: 0.0, left: 10.0, bottom: 0.0, right: 10.0)
    rankingColletionView.delegate = self
    rankingColletionView.dataSource = self
    rankingColletionView.showsHorizontalScrollIndicator = false
    rankingColletionView.backgroundColor = ANIColor.bg
    let id = NSStringFromClass(ANIStoryRankingCell.self)
    rankingColletionView.register(ANIStoryRankingCell.self, forCellWithReuseIdentifier: id)
    addSubview(rankingColletionView)
    rankingColletionView.edgesToSuperview()
    self.rankingColletionView = rankingColletionView
  }
  
  private func setupNotifications() {
    removeNotifications()
    ANINotificationManager.receive(reloadRankingStory: self, selector: #selector(deleteUsers))
  }
  
  private func removeNotifications() {
    ANINotificationManager.remove(self)
  }
  
  @objc private func deleteUsers() {
    self.users.removeAll()
  }
  
  private func isBlockStory(story: FirebaseStory) -> Bool {
    guard let currentUserUid = ANISessionManager.shared.currentUserUid else { return false }
    
    if let blockUserIds = ANISessionManager.shared.blockUserIds, blockUserIds.contains(story.userId) {
      return true
    }
    if let blockingUserIds = ANISessionManager.shared.blockingUserIds, blockingUserIds.contains(story.userId) {
      return true
    }
    if let hideUserIds = story.hideUserIds, hideUserIds.contains(currentUserUid) {
      return true
    }
    if story.storyImageUrls == nil && story.recruitId == nil && story.thumbnailImageUrl == nil {
      return true
    }
    
    return false
  }
}

//MARK: UICollectionViewDataSource
extension ANIStoryRankingView: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return rankingStories.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let id = NSStringFromClass(ANIStoryRankingCell.self)
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! ANIStoryRankingCell
    
    if users.contains(where: { $0.uid == rankingStories[indexPath.item].userId }) {
      for user in users {
        if rankingStories[indexPath.item].userId == user.uid {
          cell.user = user
          break
        }
      }
    } else {
      cell.user = nil
    }
    cell.rankingStory = rankingStories[indexPath.item]
    if indexPath.item == 0 {
      cell.crownImage = UIImage(named: "goldCrown")
    } else if indexPath.item == 1 {
      cell.crownImage = UIImage(named: "silverCrown")
    } else if indexPath.item == 2 {
      cell.crownImage = UIImage(named: "brownCrown")
    } else {
      cell.crownImage = UIImage()
    }
    cell.delegate = self
    
    return cell
  }
}

//MARK: UICollectionViewDelegate
extension ANIStoryRankingView: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    if !isBlockStory(story: rankingStories[indexPath.item]) {
      self.delegate?.didSelectRankingCell(rankingStory: rankingStories[indexPath.item], ranking: indexPath.item)
    }
  }
}


//MARK: UICollectionViewDelegateFlowLayout
extension ANIStoryRankingView: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let size = CGSize(width: ANIStoryRankingCell.share.RANKING_COLLECTION_VIEW_CELL_WIDHT, height: ANIStoryRankingCell.share.RANKING_COLLECTION_VIEW_CELL_WIDHT + ANIStoryRankingCell.share.STORY_LABEL_HEIHGT + ANIStoryRankingCell.share.PROFILE_IMAGE_VIEW_HEIGHT + ANIStoryRankingCell.share.MARGIN)
    return size
  }
}

//MARK: ANIStoryRankingCellDelegate
extension ANIStoryRankingView: ANIStoryRankingCellDelegate {
  func loadedUser(user: FirebaseUser) {
    self.users.append(user)
  }
}
