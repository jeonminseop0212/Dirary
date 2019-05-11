//
//  UIApplication.swift
//  Ani
//
//  Created by jeonminseop on 2018/04/26.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

extension UIApplication {
  var statusBar: UIView? {
    return value(forKey: "statusBar") as? UIView
  }
  
  class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
    if let navigationController = controller as? UINavigationController {
      return topViewController(controller: navigationController.visibleViewController)
    }
    if let tabController = controller as? UITabBarController {
      if let selected = tabController.selectedViewController {
        return topViewController(controller: selected)
      }
    }
    if let presented = controller?.presentedViewController {
      return topViewController(controller: presented)
    }
    return controller
  }
}
