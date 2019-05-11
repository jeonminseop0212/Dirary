//
//  ANIContributionView.swift
//  Ani
//
//  Created by jeonminseop on 2018/05/17.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import ActiveLabel

protocol ANIContributionViewDelegate {
  func imagesPickCellTapped()
  func imageDeleteButtonTapped(index: Int)
  func videoDeleteButtonTapped()
  func contributionButtonOn(on: Bool)
  func twitterLink()
}

class ANIContributionView: UIView {
  
  private weak var scrollView: ANIScrollView?
  private weak var contentView: UIView?
  
  private weak var contentTextView: ANIPlaceHolderTextView?
  private let CONTENT_IMAGES_VIEW_RATIO: CGFloat = 0.5
  private weak var contentImagesView: ANIContributionImagesView?
  
  private weak var twitterShareBase: UIView?
  private weak var twtiterShareImageView: UIImageView?
  private weak var twitterShareLabel: UILabel?
  private weak var twitterShareOnLabel: UILabel?
  
  var contentImages = [UIImage?]() {
    didSet {
      guard let contentImagesView = self.contentImagesView else { return }
      
      contentImagesView.contentImages = contentImages
      
      if isContributable() {
        self.delegate?.contributionButtonOn(on: true)
      } else {
        self.delegate?.contributionButtonOn(on: false)
      }
    }
  }
  
  var videoLength: Int = 0
  var thumbnailImage: UIImage? {
    didSet {
      guard let contentImagesView = self.contentImagesView else { return }
      
      contentImagesView.videoLength = videoLength
      contentImagesView.thumbnailImage = thumbnailImage
      
      if isContributable() {
        self.delegate?.contributionButtonOn(on: true)
      } else {
        self.delegate?.contributionButtonOn(on: false)
      }
    }
  }
  
  var selectedContributionMode: ContributionMode? {
    didSet {
      guard let selectedContributionMode = self.selectedContributionMode,
            let contentTextView = self.contentTextView,
            let contentImagesView = self.contentImagesView else { return }
      
      if selectedContributionMode == .story {
        contentTextView.placeHolder = "どんな話でも大丈夫です*^_^*"
      } else if selectedContributionMode == .qna {
        contentTextView.placeHolder = "どんな質問でも大丈夫です*^_^*"
      }
      
      contentImagesView.selectedContributionMode = selectedContributionMode
    }
  }
  
  private let KEYBOARD_HIDE_TOOL_BAR_HEIGHT: CGFloat = 40.0
  
  private var isTwitterToggleAnimation: Bool = false
  
  var delegate: ANIContributionViewDelegate?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    let userDefaults = UserDefaults.standard

    //scrollView
    let scrollView = ANIScrollView()
    addSubview(scrollView)
    scrollView.edgesToSuperview()
    self.scrollView = scrollView
    
    //contentView
    let contentView = UIView()
    scrollView.addSubview(contentView)
    contentView.edgesToSuperview()
    contentView.width(to: scrollView)
    self.contentView = contentView
    
    //contentTextView
    let contentTextView = ANIPlaceHolderTextView()
    contentTextView.keyboardType = .twitter
    contentTextView.textColor = ANIColor.dark
    contentTextView.font = UIFont.systemFont(ofSize: 17.0)
    contentTextView.isScrollEnabled = false
    contentTextView.delegate = self
    contentView.addSubview(contentTextView)
    let insets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: -10.0, right: 8.0)
    contentTextView.edgesToSuperview(excluding: .bottom, insets: insets)
    self.contentTextView = contentTextView
    setHideButtonOnKeyboard(textView: contentTextView)
    
    //contentImagesView
    let contentImagesView = ANIContributionImagesView()
    contentImagesView.delegate = self
    contentView.addSubview(contentImagesView)
    contentImagesView.topToBottom(of: contentTextView, offset: 5.0)
    contentImagesView.leftToSuperview()
    contentImagesView.rightToSuperview()
    contentImagesView.height(UIScreen.main.bounds.width * CONTENT_IMAGES_VIEW_RATIO)
    self.contentImagesView = contentImagesView
    
    //twitterShareBase
    let twitterShareBase = UIView()
    twitterShareBase.isUserInteractionEnabled = true
    twitterShareBase.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(twitterShareToggle)))
    contentView.addSubview(twitterShareBase)
    twitterShareBase.topToBottom(of: contentImagesView, offset: 15.0)
    twitterShareBase.leftToSuperview(offset: 15.0)
    twitterShareBase.bottomToSuperview(offset: -10.0)
    self.twitterShareBase = twitterShareBase
    
    //twtiterShareImageView
    let twtiterShareImageView = UIImageView()
    twtiterShareImageView.image = UIImage(named: "twitter")?.withRenderingMode(.alwaysTemplate)
    if userDefaults.bool(forKey: KEY_IS_TWITTER_SHARE) {
      twtiterShareImageView.tintColor = ANIColor.lightBlue
    } else {
      twtiterShareImageView.tintColor = ANIColor.darkGray
    }
    twtiterShareImageView.contentMode = .scaleAspectFit
    twitterShareBase.addSubview(twtiterShareImageView)
    twtiterShareImageView.topToSuperview()
    twtiterShareImageView.leftToSuperview()
    twtiterShareImageView.width(17.0)
    twtiterShareImageView.height(17.0)
    twtiterShareImageView.bottomToSuperview()
    self.twtiterShareImageView = twtiterShareImageView
    
    //twitterShareLabel
    let twitterShareLabel = UILabel()
    twitterShareLabel.text = "Twitterにも投稿"
    twitterShareLabel.font = UIFont.systemFont(ofSize: 15.0)
    twitterShareLabel.textColor = ANIColor.darkGray
    twitterShareBase.addSubview(twitterShareLabel)
    twitterShareLabel.leftToRight(of: twtiterShareImageView, offset: 5.0)
    twitterShareLabel.centerYToSuperview()
    self.twitterShareLabel = twitterShareLabel
    
    //twitterShareOnLabel
    let twitterShareOnLabel = UILabel()
    if userDefaults.bool(forKey: KEY_IS_TWITTER_SHARE) {
      twitterShareOnLabel.text = "ON"
    } else {
      twitterShareOnLabel.text = "OFF"
    }
    twitterShareOnLabel.font = UIFont.systemFont(ofSize: 15.0)
    twitterShareOnLabel.textColor = ANIColor.darkGray
    twitterShareBase.addSubview(twitterShareOnLabel)
    twitterShareOnLabel.leftToRight(of: twitterShareLabel, offset: 5.0)
    twitterShareOnLabel.rightToSuperview()
    twitterShareOnLabel.centerYToSuperview()
    self.twitterShareOnLabel = twitterShareOnLabel
  }
  
  func getContent() -> String {
    guard let contentTextView = self.contentTextView,
          let text = contentTextView.text else { return "" }
    
    return text
  }
  
  private func isContributable() -> Bool {
    guard let selectedContributionMode = self.selectedContributionMode,
          let contentTextView = self.contentTextView else { return false }
    
    switch selectedContributionMode {
    case .story:
      if !contentImages.isEmpty || thumbnailImage != nil {
        return true
      } else {
        return false
      }
    case .qna:
      if contentTextView.text.count > 0 {
        return true
      } else {
        return false
      }
    }
  }
  
  private func setHideButtonOnKeyboard(textView: UITextView) {
    let tools = UIToolbar()
    tools.tintColor = ANIColor.emerald
    tools.frame = CGRect(x: 0, y: 0, width: frame.width, height: KEYBOARD_HIDE_TOOL_BAR_HEIGHT)
    let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
    let closeButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(keyboardHideButtonTapped))
    tools.items = [spacer, closeButton]
    textView.inputAccessoryView = tools
  }
  
  //MARK: action
  @objc private func keyboardHideButtonTapped() {
    self.endEditing(true)
    self.resignFirstResponder()
  }
  
  @objc func twitterShareToggle() {
    guard let currentUser = ANISessionManager.shared.currentUser,
          let twtiterShareImageView = self.twtiterShareImageView,
          let twitterShareOnLabel = self.twitterShareOnLabel,
          !isTwitterToggleAnimation else { return }
    
    if let isTwitterLink = currentUser.isTwitterLink, isTwitterLink {
      let userDefaults = UserDefaults.standard
      if userDefaults.bool(forKey: KEY_IS_TWITTER_SHARE) {
        isTwitterToggleAnimation = true

        UIView.animate(withDuration: 0.2, animations: {
          twtiterShareImageView.tintColor = ANIColor.darkGray
          twitterShareOnLabel.text = "OFF"
        }) { (complete) in
          self.isTwitterToggleAnimation = false
        }

        userDefaults.set(false, forKey: KEY_IS_TWITTER_SHARE)
      } else {
        isTwitterToggleAnimation = true

        UIView.animate(withDuration: 0.2, animations: {
          twtiterShareImageView.tintColor = ANIColor.lightBlue
          twitterShareOnLabel.text = "ON"
        }) { (complete) in
          self.isTwitterToggleAnimation = false
        }
        
        userDefaults.set(true, forKey: KEY_IS_TWITTER_SHARE)
      }
    } else {
      self.delegate?.twitterLink()
    }
  }
}

//MARK: ANIContributionImagesViewDelegate
extension ANIContributionView: ANIContributionImagesViewDelegate {
  func imagesPickCellTapped() {
    self.delegate?.imagesPickCellTapped()
  }
  
  func imageDelete(index: Int) {
    contentImages.remove(at: index)
    self.delegate?.imageDeleteButtonTapped(index: index)
  }
  
  func videoDelete() {
    thumbnailImage = nil
    self.delegate?.videoDeleteButtonTapped()
  }
}

//MARK: UITextViewDelegate
extension ANIContributionView: UITextViewDelegate {
  func textViewDidChange(_ textView: UITextView) {
    if let textView = textView as? ANIPlaceHolderTextView, textView.markedTextRange == nil {
      
      var replaceText: String = textView.text
      if let range = replaceText.range(of: "＃") {
        replaceText.replaceSubrange(range, with: "#")
        textView.text = replaceText
      }
      
      let activtyLabel = ActiveLabel()
      activtyLabel.text = replaceText
      
      if !activtyLabel.hashtagElements.isEmpty {
        textView.resolveHashTags(text: replaceText, hashtagArray: activtyLabel.hashtagElements)
      } else {
        let attrs = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17.0), NSAttributedString.Key.foregroundColor: ANIColor.dark]

        textView.typingAttributes = attrs
        
        let attrString = NSMutableAttributedString(string: replaceText, attributes: attrs)
        textView.attributedText = attrString
      }
    }
    
    if isContributable() {
      self.delegate?.contributionButtonOn(on: true)
    } else {
      self.delegate?.contributionButtonOn(on: false)
    }
  }
  
  func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    textView.typingAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17.0), NSAttributedString.Key.foregroundColor: ANIColor.dark]
    
    return true
  }
}
