//
//  FirebaseQna.swift
//  Ani
//
//  Created by jeonminseop on 2018/06/06.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

struct FirebaseQna: Codable {
  var id: String?
  let qnaImageUrls: [String]?
  let qna: String
  let userId: String
  let date: String
  var isLoved: Bool?
  var hideUserIds: [String]?
  var hashtags: [String: String]?
  var comments: [FirebaseComment]?
}
