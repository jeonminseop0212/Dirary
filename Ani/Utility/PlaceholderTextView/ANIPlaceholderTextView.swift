//
//  PlaceholderTextView.swift
//  Ani
//
//  Created by jeonminseop on 2018/05/14.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

public class ANIPlaceHolderTextView: UITextView {
  
  lazy var placeHolderLabel: UILabel = UILabel()
  var placeHolderColor: UIColor = .lightGray
  var placeHolder: NSString = ""
  
  public override init(frame: CGRect, textContainer: NSTextContainer?) {
    super.init(frame: frame, textContainer: textContainer)
    
    setupNotifications()
  }
  
  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setupNotifications() {
    ANINotificationManager.receive(textViewTextDidChange: self, selector: #selector(textChanged))
  }
  
  deinit {
    ANINotificationManager.remove(self)
  }

  override public func draw(_ rect: CGRect) {
    super.draw(rect)

    if(self.placeHolder.length > 0) {
      self.placeHolderLabel.frame = CGRect(x: 5.0, y: 8.0, width: self.bounds.size.width  - 16.0, height: 0.0)
      self.placeHolderLabel.lineBreakMode = .byWordWrapping
      self.placeHolderLabel.numberOfLines = 0
      self.placeHolderLabel.font = self.font
      self.placeHolderLabel.backgroundColor = .clear
      self.placeHolderLabel.textColor = self.placeHolderColor
      self.placeHolderLabel.alpha = 0.0
      self.placeHolderLabel.tag = 1
      
      self.placeHolderLabel.text = self.placeHolder as String
      self.placeHolderLabel.sizeToFit()
      self.addSubview(placeHolderLabel)
    }
    
    self.sendSubviewToBack(placeHolderLabel)
    
    if self.text.utf16.count == 0 && self.placeHolder.length > 0 {
      self.viewWithTag(1)?.alpha = 1
    }
  }
  
  @objc public func textChanged(notification:NSNotification?) -> (Void) {
    if self.placeHolder.length == 0 {
      return
    }
    
    if self.text.utf16.count == 0 {
      self.viewWithTag(1)?.alpha = 1
    } else {
      self.viewWithTag(1)?.alpha = 0
    }
  }
  
  func showPlaceHolder() {
    self.viewWithTag(1)?.alpha = 1
  }
  
  func resolveHashTags(text: String, hashtagArray: [String]) {
    var nsText: NSString = text as NSString
    var ranges = [NSRange]()
    
    var replaceRanges = [NSRange]()
    
    for (index, word) in hashtagArray.enumerated() {
      var newWord = ""
      //タグが文字列の一番前にいる時
      var range = nsText.range(of: "#" + word as String)
      if range.lowerBound == 0 && index == 0 {
        newWord = "#" + word
      } else {
        //普通の場合
        range = nsText.range(of: " #" + word as String)
        if range.length > 0 {
          newWord = " #" + word
        } else {
          //改行の次にタグが来る場合
          range = nsText.range(of: "\n#" + word as String)
          if range.length > 0 {
            newWord = "\n#" + word
          }
        }
      }
      
      if !ranges.isEmpty, let lastRage = ranges.last {
        range = NSRange(location: lastRage.upperBound + range.lowerBound, length: newWord.count)
      }
      
      ranges.append(range)
      
      //絵文字が入るとずれるから絵文字をなくして計算する
      let replaceText = textEmojiExclusion(checkString: nsText as String) as NSString
      var replaceRange = replaceText.range(of: newWord as String)
      if !replaceRanges.isEmpty, let lastReplaceRage = replaceRanges.last {
        replaceRange = NSRange(location: lastReplaceRage.upperBound + replaceRange.lowerBound, length: newWord.count)
      }
      
      replaceRanges.append(replaceRange)
      
      nsText = text[text.index(text.startIndex, offsetBy: replaceRange.upperBound)...] as NSString
    }
    
    let attrs = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17.0), NSAttributedString.Key.foregroundColor: ANIColor.dark]

    let attrString = NSMutableAttributedString(string: text, attributes: attrs)

    if(ranges.count != 0) {
      let attrs = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17.0), NSAttributedString.Key.foregroundColor: ANIColor.darkblue]
      for range in ranges {
        attrString.addAttributes(attrs, range: range)
      }
    }
    
    let cursorPoint = getCursorPosition()

    self.attributedText = attrString
    
    updateCursorPoint(cursorPoint: cursorPoint)
  }
  
  private func textEmojiExclusion(checkString: String) -> String {
    var replaceText = ""
    let replaceCh = "E"
    for ch in checkString {
      let str: String = ch.description
      if str.isAppleColorEmoji {
        replaceText += replaceCh
      } else {
        replaceText += str
      }
    }
    
    return replaceText
  }
  
  private func getCursorPosition() -> Int {
    if let selectedRange = self.selectedTextRange {
      let cursorPosition = self.offset(from: self.beginningOfDocument, to: selectedRange.start)
      
      return cursorPosition
    }
    
    return 0
  }
  
  private func updateCursorPoint(cursorPoint: Int) {
    if let newPosition = self.position(from: self.beginningOfDocument, offset: cursorPoint) {
      self.selectedTextRange = self.textRange(from: newPosition, to: newPosition)
    }
  }
}
