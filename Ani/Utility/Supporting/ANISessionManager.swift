//
//  ANISessionManager.swift
//  Ani
//
//  Created by jeonminseop on 2018/05/31.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

class ANISessionManager: NSObject {
  static let shared = ANISessionManager()
  
  var currentUser: FirebaseUser? {
    didSet {
      guard let currentUser = self.currentUser,
            let checkNotiDate = currentUser.checkNotiDate else { return }
      
      self.checkNotiDate = checkNotiDate
    }
  }
  
  var isHaveUnreadNoti: Bool = false {
    didSet {
      ANINotificationManager.postChangeIsHaveUnreadNoti()
    }
  }
  
  var isHaveUnreadMessage: Bool = false {
    didSet {
      ANINotificationManager.postChangeIsHaveUnreadMessage()
    }
  }
  
  var onlineChatGroupId: String?
  
  var checkNotiDate: String?
  
  var currentUserUid: String?
  
  var isAnonymous: Bool = false
  
  var blockUserIds: [String]?
  var blockingUserIds: [String]?
  
  var isLoadedFirstData: Bool = false
  var isCheckedVersion: Bool = false
  
  var isLaunchNoti: Bool = false
  
  var showReviewConditions: [String: Int]?
  
  var isHiddenInitial: Bool = true
  var isHiddenSplash: Bool = false
  var isShowEvent: Bool = false
}
