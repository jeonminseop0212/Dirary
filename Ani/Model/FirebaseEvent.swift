//
//  FirebaseEvent.swift
//  Ani
//
//  Created by jeonminseop on 2019/01/29.
//  Copyright © 2019 JeonMinseop. All rights reserved.
//

import UIKit

struct FirebaseEvent: Codable {
  let id: String
  let title: String?
  let subtitle: String?
  let date: String?
  let imageUrl: String?
  let detailUrl: String?
}
