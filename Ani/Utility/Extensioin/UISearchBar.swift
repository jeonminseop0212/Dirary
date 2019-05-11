//
//  UISearchBar.swift
//  Ani
//
//  Created by 전민섭 on 2018/04/06.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

extension UISearchBar {
  var textField: UITextField? {
    return value(forKey: "_searchField") as? UITextField
  }
  
  func disableBlur() {
    backgroundImage = UIImage()
    isTranslucent = true
  }
  
  var cancelButton: UIButton? {
    return value(forKey: "_cancelButton") as? UIButton
  }
}
