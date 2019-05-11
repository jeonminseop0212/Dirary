//
//  FirebaseNoti.swift
//  Ani
//
//  Created by jeonminseop on 2018/07/09.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

struct FirebaseNotification: Codable {
  let userId: String
  let userName: String
  let noti: String
  let contributionKind: String
  let notiKind: String
  let notiId: String
  let commentId: String?
  let updateDate: String
}
