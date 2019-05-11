//
//  ANIFirebase.swift
//  Ani
//
//  Created by jeonminseop on 2018/11/16.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import Firebase

class ANIFirebase: NSObject{
  static var isInit: Bool = false
  static var FIREBASE_PLIST_NAME: String {
    return IS_DEBUG ? "GoogleService-Info" : "GoogleService-Info-release"
  }
  
  override init() {
    guard !ANIFirebase.isInit else { return }
    ANIFirebase.isInit = true
    guard let path = Bundle.main.path(forResource: ANIFirebase.FIREBASE_PLIST_NAME, ofType: "plist") else {
      ALog("invalid firebase plist file : \(ANIFirebase.FIREBASE_PLIST_NAME)")
      return
    }
    guard let firbaseOptions = FirebaseOptions(contentsOfFile: path) else {
      ALog("not make firbaseOptions : \(ANIFirebase.FIREBASE_PLIST_NAME)")
      return
    }
    FirebaseApp.configure(options: firbaseOptions)
  }
}
