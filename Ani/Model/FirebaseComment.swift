//
//  FirebaseComment.swift
//  Ani
//
//  Created by jeonminseop on 2018/06/06.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

struct FirebaseComment: Codable {
  let id: String
  let userId: String
  let comment: String
  let date: String
  var isLoved: Bool?
  let parentCommentId: String?
  let parentCommentUserId: String?
}
