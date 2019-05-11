//
//  ANIPopularUsers.swift
//  Ani
//
//  Created by jeonminseop on 2019/02/16.
//  Copyright © 2019 JeonMinseop. All rights reserved.
//

import UIKit
import FirebaseFirestore
import CodableFirebase

protocol ANIPopularUsersViewDelegate {
  func popularUsersViewDidScroll(scrollY: CGFloat)
  func reject()
}

class ANIPopularUsersView: UIView {
  
  private weak var collectionView: UICollectionView?
  
  private weak var activityIndicatorView: ANIActivityIndicator?
  
  private weak var refreshControl: UIRefreshControl?
  
  private var users = [FirebaseUser]()
  
  var delegate: ANIPopularUsersViewDelegate?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setup()
    loadPopularUsers(sender: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    self.backgroundColor = ANIColor.bg

    //collectionView
    let flowLayout = UICollectionViewFlowLayout()
    flowLayout.scrollDirection = .vertical
    flowLayout.minimumLineSpacing = 10.0
    flowLayout.minimumInteritemSpacing = 10.0
    flowLayout.sectionInset = UIEdgeInsets(top: 0.0, left: 10.0, bottom: 10.0, right: 10.0)
    let collectionView = UICollectionView(frame: self.frame, collectionViewLayout: flowLayout)
    let topInset = UIViewController.NAVIGATION_BAR_HEIGHT + ANIRecruitViewController.FILTERS_VIEW_HEIGHT
    collectionView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
    collectionView.scrollIndicatorInsets = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
    collectionView.backgroundColor = ANIColor.bg
    collectionView.alpha = 0.0
    collectionView.dataSource = self
    collectionView.delegate = self
    let userCellId = NSStringFromClass(ANIPopularUserCell.self)
    collectionView.register(ANIPopularUserCell.self, forCellWithReuseIdentifier: userCellId)
    let headerCellId = NSStringFromClass(ANIPopularUserHeaderCell.self)
    collectionView.register(ANIPopularUserHeaderCell.self, forCellWithReuseIdentifier: headerCellId)
    let refreshControl = UIRefreshControl()
    refreshControl.backgroundColor = .clear
    refreshControl.tintColor = ANIColor.moreDarkGray
    refreshControl.addTarget(self, action: #selector(reloadData(sender:)), for: .valueChanged)
    self.refreshControl = refreshControl
    collectionView.addSubview(refreshControl)
    self.addSubview(collectionView)
    collectionView.edgesToSuperview()
    self.collectionView = collectionView
    
    //activityIndicatorView
    let activityIndicatorView = ANIActivityIndicator()
    activityIndicatorView.isFull = false
    self.addSubview(activityIndicatorView)
    activityIndicatorView.edgesToSuperview()
    self.activityIndicatorView = activityIndicatorView
  }
  
  @objc private func reloadData(sender:  UIRefreshControl?) {
    self.loadPopularUsers(sender: sender)
  }
  
  func endRefresh() {
    guard let refreshControl = self.refreshControl,
          let collectionView = self.collectionView else { return }
    
    refreshControl.endRefreshing()
    
    let topInset = UIViewController.NAVIGATION_BAR_HEIGHT + ANIRecruitViewController.FILTERS_VIEW_HEIGHT
    if collectionView.contentOffset.y + topInset < 0 {
      collectionView.scrollToItem(at: [0, 0], at: .top, animated: false)
    }
  }
  
  private func isBlockUser(user: FirebaseUser) -> Bool {
    guard let userId = user.uid else { return false }
    
    if let blockUserIds = ANISessionManager.shared.blockUserIds, blockUserIds.contains(userId) {
      return true
    }
    if let blockingUserIds = ANISessionManager.shared.blockingUserIds, blockingUserIds.contains(userId) {
      return true
    }
    
    return false
  }
}

//MARK: UICollectionViewDataSource
extension ANIPopularUsersView: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return users.count + 1
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if indexPath.item == 0 {
      let headerCellId = NSStringFromClass(ANIPopularUserHeaderCell.self)
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: headerCellId, for: indexPath) as! ANIPopularUserHeaderCell
      return cell
    } else {
      let userCellId = NSStringFromClass(ANIPopularUserCell.self)
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: userCellId, for: indexPath) as! ANIPopularUserCell
      cell.delegate = self
      
      if users.count > indexPath.item - 1 {
        cell.user = users[indexPath.item - 1]
      }
      
      return cell
    }
  }
}

//MARK: UICollectionViewDelegate
extension ANIPopularUsersView: UICollectionViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    ANINotificationManager.postViewScrolled()
    
    //navigation bar animation
    let scrollY = scrollView.contentOffset.y
    self.delegate?.popularUsersViewDidScroll(scrollY: scrollY)
  }
}

//MARK: UICollectionViewDelegateFlowLayout
extension ANIPopularUsersView: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    if indexPath.item == 0 {
      return CGSize(width: self.frame.size.width, height: 20.0)
    } else {
      return CGSize(width: self.frame.size.width / 2 - 15.0, height: 250.0)
    }
  }
}

//MARK: ANIPopularUserCellDelegate
extension ANIPopularUsersView: ANIPopularUserCellDelegate {
  func reject() {
    self.delegate?.reject()
  }
}

//MARK: data
extension ANIPopularUsersView {
  private func loadPopularUsers(sender: UIRefreshControl?) {
    guard let activityIndicatorView = self.activityIndicatorView,
          let collectionView = self.collectionView else { return }
    
    if !self.users.isEmpty {
      self.users.removeAll()
    }
    
    if sender == nil {
      activityIndicatorView.startAnimating()
    }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      database.collection(KEY_POPULAR_USERS).order(by: KEY_ORDER, descending: false).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          
          if let sender = sender {
            sender.endRefreshing()
          }
          
          return
        }
        
        guard let snapshot = snapshot else { return }
        let group = DispatchGroup()
        var usersTemp = [FirebaseUser?]()

        for (index, document) in snapshot.documents.enumerated() {
          group.enter()
          usersTemp.append(nil)
          
          DispatchQueue(label: "popularUser").async {
            database.collection(KEY_USERS).document(document.documentID).getDocument(completion: { (userSnapshot, userError) in
              if let userError = userError {
                DLog("Error get document: \(userError)")
                group.leave()
                
                return
              }

              guard let recruitSnapshot = userSnapshot, let data = recruitSnapshot.data() else {
                group.leave()
                return
              }
              
              do {
                let user = try FirestoreDecoder().decode(FirebaseUser.self, from: data)
                usersTemp[index] = user
                
                group.leave()
              } catch let error {
                DLog(error)
                
                group.leave()
              }
            })
          }
        }
        
        group.notify(queue: DispatchQueue(label: "popularUser")) {
          DispatchQueue.main.async {
            for user in usersTemp {
              if let user = user {
                self.users.append(user)
              }
            }
            
            if let sender = sender {
              sender.endRefreshing()
            }
            
            collectionView.reloadData()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
              activityIndicatorView.stopAnimating()

              UIView.animate(withDuration: 0.2, animations: {
                collectionView.alpha = 1.0
              })
            })
          }
        }
      })
    }
  }
}
