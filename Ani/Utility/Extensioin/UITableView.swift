//
//  UITableView.swift
//  Ani
//
//  Created by jeonminseop on 2018/10/02.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

extension UITableView {
  func reloadData(completion:(()->())? = nil){
    UIView.animate(withDuration: 0, animations: {self.reloadData()}, completion: {_ in completion?()})
  }
}
