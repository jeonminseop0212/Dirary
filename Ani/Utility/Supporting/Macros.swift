//
//  Macros.swift
//  Ani
//
//  Created by jeonminseop on 2018/09/25.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

#if DEBUG
let IS_DEBUG = true
#else
let IS_DEBUG = false
#endif

func DLog(_ obj: Any? = nil, file: String = #file, function: String = #function, line: Int = #line) {
  #if DEBUG
  var filename: NSString = file as NSString
  filename = filename.lastPathComponent as NSString
  if let obj = obj {
    print("[File:\(filename) Func:\(function) Line:\(line)] : \(obj)")
  } else {
    print("[File:\(filename) Func:\(function) Line:\(line)]")
  }
  #endif
}

func ALog(_ obj: Any? = nil, file: String = #file, function: String = #function, line: Int = #line) {
  var filename: NSString = file as NSString
  filename = filename.lastPathComponent as NSString
  if let obj = obj {
    NSLog("[File:\(filename) Func:\(function) Line:\(line)] : \(obj)")
  } else {
    NSLog("[File:\(filename) Func:\(function) Line:\(line)]")
  }
}
