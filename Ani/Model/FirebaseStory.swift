//
//  FirebaseStory.swift
//  Ani
//
//  Created by jeonminseop on 2018/06/06.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

struct FirebaseStory: Codable {
  var id: String?
  let storyImageUrls: [String]?
  var storyVideoUrl: String?
  var thumbnailImageUrl: String?
  let story: String
  let userId: String
  let recruitId: String?
  let recruitTitle: String?
  let recruitSubTitle: String?
  let date: String
  let day: String?
  var isLoved: Bool?
  var hideUserIds: [String]?
  var loveCount: Int?
  var hashtags: [String: String]?
  var comments: [FirebaseComment]?
}

