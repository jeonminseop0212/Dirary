//
//  UIString.swift
//  Ani
//
//  Created by jeonminseop on 2018/05/16.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

private var appleColorEmojiFont = CTFontCreateWithName("AppleColorEmoji" as CFString, 20, nil)

extension String {
  func substring(_ r: CountableRange<Int>) -> String {
    
    let length = self.count
    let fromIndex = (r.startIndex > 0) ? self.index(self.startIndex, offsetBy: r.startIndex) : self.startIndex
    let toIndex = (length > r.endIndex) ? self.index(self.startIndex, offsetBy: r.endIndex) : self.endIndex
    
    if fromIndex >= self.startIndex && toIndex <= self.endIndex {
      return String(self[fromIndex..<toIndex])
    }
    
    return String(self)
  }
  
  func substring(_ r: CountableClosedRange<Int>) -> String {
    
    let from = r.lowerBound
    let to = r.upperBound
    
    return self.substring(from..<(to+1))
  }
  
  func substring(_ r: CountablePartialRangeFrom<Int>) -> String {
    
    let from = r.lowerBound
    let to = self.count
    
    return self.substring(from..<to)
  }
  
  func substring(_ r: PartialRangeThrough<Int>) -> String {
    
    let from = 0
    let to = r.upperBound
    
    return self.substring(from..<to)
  }
  
  var isAppleColorEmoji: Bool {
    let chars = Array(self.utf16)
    if chars.count == 1 && chars[0] <= 57 { // 制御文字やスペース、数字を除外
      return false
    }
    var glyphs = [CGGlyph](repeating: 0, count: chars.count)
    return CTFontGetGlyphsForCharacters(appleColorEmojiFont, chars, &glyphs, glyphs.count)
  }
}
