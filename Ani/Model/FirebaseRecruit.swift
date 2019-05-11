//
//  FirebaseRecruit.swift
//  Ani
//
//  Created by jeonminseop on 2018/06/05.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

struct FirebaseRecruit: Codable {
  var id: String?
  var headerImageUrl: String?
  let title: String
  let kind: String
  let age: String
  let sex: String
  let home: String
  let vaccine: String
  let castration: String
  let reason: String
  let introduce: String
  var introduceImageUrls: [String]?
  let passing: String
  let recruitState: Int
  let userId: String
  let date: String
  var isLoved: Bool?
  var isCliped: Bool?
  var isSupported: Bool?
  var hideUserIds: [String]?
}
