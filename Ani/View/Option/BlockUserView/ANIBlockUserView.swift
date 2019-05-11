//
//  ANIBlockUserView.swift
//  Ani
//
//  Created by jeonminseop on 2018/11/12.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import FirebaseFirestore
import CodableFirebase

protocol ANIBlockUserViewDelegate {
  func blockButtonTapped(user: FirebaseUser, isBlock: Bool)
}

class ANIBlockUserView: UIView {
  
  private weak var blockUserTableView: UITableView?
  
  private weak var activityIndicatorView: ANIActivityIndicator?

  private var blockUsers = [FirebaseUser]()
  
  private var isLastPage: Bool = false
  private var lastContent: QueryDocumentSnapshot?
  private var isLoading: Bool = false
  private let COUNT_LAST_CELL: Int = 4
  
  private var cellHeight = [IndexPath: CGFloat]()
  
  var delegate: ANIBlockUserViewDelegate?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setup()
    loadBlockUser(sender: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    self.backgroundColor = .white
    
    //followUserTableView
    let blockUserTableView = UITableView()
    let id = NSStringFromClass(ANIBlockUserViewCell.self)
    blockUserTableView.register(ANIBlockUserViewCell.self, forCellReuseIdentifier: id)
    blockUserTableView.separatorStyle = .none
    blockUserTableView.alpha = 0.0
    blockUserTableView.rowHeight = UITableView.automaticDimension
    blockUserTableView.dataSource = self
    blockUserTableView.delegate = self
    let refreshControl = UIRefreshControl()
    refreshControl.backgroundColor = .clear
    refreshControl.tintColor = ANIColor.moreDarkGray
    refreshControl.addTarget(self, action: #selector(reloadData(sender:)), for: .valueChanged)
    blockUserTableView.addSubview(refreshControl)
    addSubview(blockUserTableView)
    blockUserTableView.edgesToSuperview()
    self.blockUserTableView = blockUserTableView
    
    //activityIndicatorView
    let activityIndicatorView = ANIActivityIndicator()
    activityIndicatorView.isFull = false
    self.addSubview(activityIndicatorView)
    activityIndicatorView.edgesToSuperview()
    self.activityIndicatorView = activityIndicatorView
  }
  
  func reloadTableView() {
    guard let blockUserTableView = self.blockUserTableView else { return }
    
    blockUserTableView.reloadData()
  }
  
  @objc private func reloadData(sender: UIRefreshControl?) {
    loadBlockUser(sender: sender)
  }
}

//MARK: UITableViewDataSource
extension ANIBlockUserView: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return blockUsers.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let id = NSStringFromClass(ANIBlockUserViewCell.self)
    let cell = tableView.dequeueReusableCell(withIdentifier: id, for: indexPath) as! ANIBlockUserViewCell
    
    cell.user = blockUsers[indexPath.row]
    cell.delegate = self
    
    return cell
  }
}

//MARK: UITableViewDelegate
extension ANIBlockUserView: UITableViewDelegate {
  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    let element = self.blockUsers.count - COUNT_LAST_CELL
    if !isLoading, indexPath.row >= element {
      loadMoreBlockUser()
    }
    
    self.cellHeight[indexPath] = cell.frame.size.height
  }
  
  func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
    if let height = self.cellHeight[indexPath] {
      return height
    } else {
      return UITableView.automaticDimension
    }
  }
}

//MARK: ANIBlockUserViewCellDelegate
extension ANIBlockUserView: ANIBlockUserViewCellDelegate {
  func blockButtonTapped(user: FirebaseUser, isBlock: Bool) {
    self.delegate?.blockButtonTapped(user: user, isBlock: isBlock)
  }
}

//MARK: data
extension ANIBlockUserView {
  private func loadBlockUser(sender: UIRefreshControl?) {
    guard let currentUserUid = ANISessionManager.shared.currentUserUid,
          let activityIndicatorView = self.activityIndicatorView,
          let blockUserTableView = self.blockUserTableView else { return }
    
    if !self.blockUsers.isEmpty {
      self.blockUsers.removeAll()
    }
    
    if sender == nil {
      activityIndicatorView.startAnimating()
    }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      self.isLoading = true
      self.isLastPage = false
      
      database.collection(KEY_USERS).document(currentUserUid).collection(KEY_BLOCK_USER_IDS).order(by: KEY_DATE, descending: true).limit(to: 20).getDocuments { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          self.isLoading = false
          
          return
        }
        
        guard let snapshot = snapshot,
          let lastContent = snapshot.documents.last else {
            self.isLoading = false
            activityIndicatorView.stopAnimating()
            
            if let sender = sender {
              sender.endRefreshing()
            }
            return }
        
        self.lastContent = lastContent
        
        let group = DispatchGroup()
        var blockUserTemp = [FirebaseUser?]()
        
        for (index, document) in snapshot.documents.enumerated() {
          
          group.enter()
          blockUserTemp.append(nil)
          
          DispatchQueue(label: "blockUser").async {
            database.collection(KEY_USERS).document(document.documentID).getDocument(completion: { (userSnapshot, userError) in
              if let error = error {
                DLog("Error get user document: \(error)")
                self.isLoading = false
                
                return
              }
              
              guard let userSnapshot = userSnapshot, let data = userSnapshot.data() else {
                group.leave()
                return
              }
              
              do {
                let user = try FirestoreDecoder().decode(FirebaseUser.self, from: data)
                blockUserTemp[index] = user
                
                group.leave()
              } catch let error {
                DLog(error)
                
                group.leave()
              }
            })
          }
        }
        
        group.notify(queue: DispatchQueue(label: "blockUser")) {
          DispatchQueue.main.async {
            DispatchQueue.main.async {
              if let sender = sender {
                sender.endRefreshing()
              }
              
              for user in blockUserTemp {
                if let user = user {
                  self.blockUsers.append(user)
                }
              }
              
              blockUserTableView.reloadData()
              activityIndicatorView.stopAnimating()
              
              UIView.animate(withDuration: 0.2, animations: {
                blockUserTableView.alpha = 1.0
              })
              
              self.isLoading = false
            }
          }
        }
      }
    }
  }
  
  private func loadMoreBlockUser() {
    guard let blockUserTableView = self.blockUserTableView,
          let lastContent = self.lastContent,
          let currentUserUid = ANISessionManager.shared.currentUserUid,
          !isLoading,
          !isLastPage else { return }

    let database = Firestore.firestore()

    DispatchQueue.global().async {
      self.isLoading = true

      database.collection(KEY_USERS).document(currentUserUid).collection(KEY_BLOCK_USER_IDS).order(by: KEY_DATE, descending: true).start(afterDocument: lastContent).limit(to: 20).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          self.isLoading = false

          return
        }

        guard let snapshot = snapshot else { return }
        guard let lastContent = snapshot.documents.last else {
          self.isLastPage = true
          self.isLoading = false
          return
        }

        self.lastContent = lastContent

        let group = DispatchGroup()
        var blockUserTemp = [FirebaseUser?]()

        for (index, document) in snapshot.documents.enumerated() {

          group.enter()
          blockUserTemp.append(nil)

          DispatchQueue(label: "blockUser").async {
            database.collection(KEY_USERS).document(document.documentID).getDocument(completion: { (userSnapshot, userError) in
              if let userError = userError {
                DLog("Error get document: \(userError)")
                self.isLoading = false

                return
              }

              guard let userSnapshot = userSnapshot, let data = userSnapshot.data() else {
                group.leave()
                return
              }

              do {
                let user = try FirestoreDecoder().decode(FirebaseUser.self, from: data)
                blockUserTemp[index] = user

                group.leave()
              } catch let error {
                DLog(error)

                group.leave()
              }
            })
          }
        }

        group.notify(queue: DispatchQueue(label: "blockUser")) {
          DispatchQueue.main.async {
            for blockUser in blockUserTemp {
              if let blockUser = blockUser {
                self.blockUsers.append(blockUser)
              }
            }
            blockUserTableView.reloadData()

            self.isLoading = false
          }
        }
      })
    }
  }
}
