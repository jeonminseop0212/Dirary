//
//  FirebaseChatMessage.swift
//  Ani
//
//  Created by jeonminseop on 2018/06/28.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

struct FirebaseChatMessage: Codable {
  let sendUserId: String
  let sendUserName: String
  let receiveUserId: String
  let message: String
  let date: String
  let isDiffrentBeforeDate: Bool?
}
