//
//  RecruitContributeView.swift
//  Ani
//
//  Created by jeonminseop on 2018/05/13.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import TinyConstraints

protocol ANIRecruitContributionViewDelegate {
  func recruitContributeViewDidScroll(offset: CGFloat)
  func imagePickButtonTapped()
  func kindSelectButtonTapped()
  func ageSelectButtonTapped()
  func sexSelectButtonTapped()
  func homeSelectButtonTapped()
  func vaccineSelectButtonTapped()
  func castrationSelectButtonTapped()
  func imagesPickCellTapped()
  func doneEditLayout()
}

class ANIRecruitContributionView: UIView {
  
  private weak var headerImageView: UIImageView?
  private var headerImageViewTopConstraint: Constraint?
  private weak var headerImagePickupButton: ANIImageButtonView?
  
  private weak var scrollView: ANIScrollView?
  private let CONTENT_SPACE: CGFloat = 25.0
  private weak var contentView: UIView?
  
  private weak var titleBG: UIView?
  private weak var titleTextView: ANIPlaceHolderTextView?

  private weak var basicInfoTitleLabel: UILabel?
  private weak var basicInfoBG: UIView?
  private weak var basicInfoLine: UIImageView?
  private weak var basicInfoKindLabel: UILabel?
  private weak var basicInfoKindSelectButton: ANIImageButtonView?
  private weak var basicInfoAgeLabel: UILabel?
  private weak var basicInfoAgeSelectButton: ANIImageButtonView?
  private weak var basicInfoSexLabel: UILabel?
  private weak var basicInfoSexSelectButton: ANIImageButtonView?
  private weak var basicInfoHomeLabel: UILabel?
  private weak var basicInfoHomeSelectButton: ANIImageButtonView?
  private weak var basicInfoVaccineLabel: UILabel?
  private weak var basicInfoVaccineSelectButton: ANIImageButtonView?
  private weak var basicInfoCastrationLabel: UILabel?
  private weak var basicInfoCastrationSelectButton: ANIImageButtonView?
  
  private weak var reasonTitleLabel: UILabel?
  private weak var reasonBG: UIView?
  private weak var reasonTextView: ANIPlaceHolderTextView?
  
  private weak var introduceTitleLabel: UILabel?
  private weak var introduceBG: UIView?
  private weak var introduceTextView: ANIPlaceHolderTextView?
  private let INTRODUCE_IMAGES_VIEW_RATIO: CGFloat = 0.5
  private weak var introduceImagesView: ANIRecruitContributionImagesView?
  
  private weak var passingTitleLabel: UILabel?
  private weak var passingSubTitleLabel: UILabel?
  private weak var passingBG: UIView?
  private weak var passingTextView: ANIPlaceHolderTextView?
  
  private weak var activityIndicatorView: ANIActivityIndicator?

  private let KEYBOARD_HIDE_TOOL_BAR_HEIGHT: CGFloat = 40.0
  
  var headerMinHeight: CGFloat?
  var headerImage: UIImage? {
    didSet {
      headerImageView?.image = headerImage
    }
  }
  
  var introduceImages = [UIImage?]() {
    didSet {
      guard let introduceImagesView = self.introduceImagesView else { return }
      introduceImagesView.introduceImages = introduceImages
    }
  }
  
  var pickMode: BasicInfoPickMode?
  private var selectedTextViewMaxY: CGFloat?
  
  var recruit: FirebaseRecruit? {
    didSet {
      guard let recruit = self.recruit,
            let headerImageUrl = recruit.headerImageUrl,
            let introduceImageUrls = recruit.introduceImageUrls,
            let scrollView = self.scrollView,
            let headerImageView = self.headerImageView,
            let headerImagePickupButton = self.headerImagePickupButton,
            let activityIndicatorView = self.activityIndicatorView else { return }

      activityIndicatorView.startAnimating()
      
      scrollView.alpha = 0.0
      headerImageView.alpha = 0.0
      headerImagePickupButton.alpha = 0.0
      
      let setUIImageGroup = DispatchGroup()
      let queue1 = DispatchQueue(label: "header")
      let queue2 = DispatchQueue(label: "introduce")
      
      queue1.async(group: setUIImageGroup) {
        setUIImageGroup.enter()
        self.setUIImageHeaderUrl(url: headerImageUrl) {
          setUIImageGroup.leave()
        }
      }
      queue2.async(group: setUIImageGroup) {
        setUIImageGroup.enter()
        self.setUIImagesFromUrls(urls: introduceImageUrls) {
          setUIImageGroup.leave()
        }
      }
      
      setUIImageGroup.notify(queue: DispatchQueue.main) {
        self.setNeedsUpdateConstraints()
        activityIndicatorView.stopAnimating()
        self.delegate?.doneEditLayout()
        
        UIView.animate(withDuration: 0.2, animations: {
          scrollView.alpha = 1.0
          headerImageView.alpha = 1.0
          headerImagePickupButton.alpha = 1.0
        })
      }
    }
  }
  
  var delegate: ANIRecruitContributionViewDelegate?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
    setNotification()
  }
  
  override func updateConstraints() {
    reloadLayout()
    super.updateConstraints()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    self.backgroundColor = .white
    
    //headerImageView
    let headerImageView = UIImageView()
    headerImageView.backgroundColor = ANIColor.bg
    addSubview(headerImageView)
    let headerImageViewHeight: CGFloat = UIScreen.main.bounds.width * UIViewController.HEADER_IMAGE_VIEW_RATIO
    headerImageViewTopConstraint = headerImageView.topToSuperview()
    headerImageView.leftToSuperview()
    headerImageView.rightToSuperview()
    headerImageView.height(headerImageViewHeight)
    self.headerImageView = headerImageView
    headerImage = UIImage(named: "headerDefault")
    
    //gradiationLayer
    let gradiationLayer = CAGradientLayer()
    let margin: CGFloat = 20.0
    gradiationLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIViewController.STATUS_BAR_HEIGHT + UIViewController.NAVIGATION_BAR_HEIGHT + margin)
    gradiationLayer.colors = [ANIColor.dark.withAlphaComponent(0.15).cgColor, ANIColor.dark.withAlphaComponent(0).cgColor]
    headerImageView.layer.addSublayer(gradiationLayer)
    
    //scrollView
    let scrollView = ANIScrollView()
    scrollView.delegate = self
    let topInset = headerImageViewHeight
    scrollView.contentInsetAdjustmentBehavior = .never
    scrollView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
    scrollView.scrollIndicatorInsets = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
    addSubview(scrollView)
    scrollView.edgesToSuperview()
    self.scrollView = scrollView
    
    //contentView
    let contentView = UIView()
    scrollView.addSubview(contentView)
    contentView.edgesToSuperview()
    contentView.width(to: scrollView)
    self.contentView = contentView
    
    //headerImagePickupButton
    let headerImagePickupButton = ANIImageButtonView()
    headerImagePickupButton.image = UIImage(named: "imagePickButton")
    headerImagePickupButton.delegate = self
    addSubview(headerImagePickupButton)
    headerImagePickupButton.width(40.0)
    headerImagePickupButton.height(40.0)
    headerImagePickupButton.right(to: headerImageView, offset: -10.0)
    headerImagePickupButton.bottom(to: headerImageView, offset: -10.0)
    self.headerImagePickupButton = headerImagePickupButton
    
    //titleBG
    let titleBG = UIView()
    contentView.addSubview(titleBG)
    titleBG.topToSuperview(offset: 10.0)
    titleBG.leftToSuperview(offset: 5.0)
    titleBG.rightToSuperview(offset: -5.0)
    self.titleBG = titleBG
    
    //titleTextView
    let titleTextView = ANIPlaceHolderTextView()
    titleTextView.backgroundColor = .white
    titleTextView.isScrollEnabled = false
    titleTextView.font = UIFont.boldSystemFont(ofSize: 20.0)
    titleTextView.textColor = ANIColor.dark
    titleTextView.placeHolder = "タイトルを入力してください"
    titleTextView.delegate = self
    titleBG.addSubview(titleTextView)
    titleTextView.edgesToSuperview()
    self.titleTextView = titleTextView
    setHideButtonOnKeyboard(textView: titleTextView)
    
    //basicInfoTitleLabel
    let basicInfoTitleLabel = UILabel()
    basicInfoTitleLabel.font = UIFont.boldSystemFont(ofSize: 20.0)
    basicInfoTitleLabel.textColor = ANIColor.dark
    basicInfoTitleLabel.text = "猫ちゃんの情報"
    contentView.addSubview(basicInfoTitleLabel)
    basicInfoTitleLabel.topToBottom(of: titleBG, offset: CONTENT_SPACE)
    basicInfoTitleLabel.leftToSuperview(offset: 10.0)
    basicInfoTitleLabel.rightToSuperview(offset: -10.0)
    self.basicInfoTitleLabel = basicInfoTitleLabel
    
    //basicInfoBG
    let basicInfoBG = UIView()
    basicInfoBG.backgroundColor = ANIColor.lightGray
    basicInfoBG.layer.cornerRadius = 10.0
    basicInfoBG.layer.masksToBounds = true
    contentView.addSubview(basicInfoBG)
    basicInfoBG.topToBottom(of: basicInfoTitleLabel, offset: 10.0)
    basicInfoBG.leftToSuperview(offset: 10.0)
    basicInfoBG.rightToSuperview(offset: -10.0)
    self.basicInfoBG = basicInfoBG
    
    //basicInfoLine
    let basicInfoLine = UIImageView()
    basicInfoLine.backgroundColor = ANIColor.bg
    basicInfoLine.image = UIImage(named: "basicInfoLine")
    basicInfoBG.addSubview(basicInfoLine)
    basicInfoLine.topToSuperview(offset: 10.0)
    basicInfoLine.width(1)
    basicInfoLine.centerXToSuperview()
    basicInfoLine.bottomToSuperview(offset: -10.0)
    self.basicInfoLine = basicInfoLine
    
    //basicInfoKindSelectButton
    let basicInfoKindSelectButton = ANIImageButtonView()
    basicInfoKindSelectButton.delegate = self
    basicInfoKindSelectButton.image = UIImage(named: "basicInfoSelectButton")
    basicInfoBG.addSubview(basicInfoKindSelectButton)
    basicInfoKindSelectButton.width(10.0)
    basicInfoKindSelectButton.height(10.0)
    basicInfoKindSelectButton.rightToLeft(of: basicInfoLine, offset: -10.0)
    self.basicInfoKindSelectButton = basicInfoKindSelectButton
    
    //basicInfoKindLabel
    let basicInfoKindLabel = UILabel()
    basicInfoKindLabel.text = "種類：選択"
    basicInfoKindLabel.font = UIFont.systemFont(ofSize: 15.0)
    basicInfoKindLabel.textColor = ANIColor.dark
    basicInfoKindLabel.numberOfLines = 0
    basicInfoKindLabel.isUserInteractionEnabled = true
    let tapKindGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(kindSelectButtonTapped))
    basicInfoKindLabel.addGestureRecognizer(tapKindGestureRecognizer)
    basicInfoBG.addSubview(basicInfoKindLabel)
    basicInfoKindLabel.topToSuperview(offset: 10.0)
    basicInfoKindLabel.leftToSuperview(offset: 10.0)
    basicInfoKindLabel.rightToLeft(of: basicInfoKindSelectButton, offset: -10.0)
    self.basicInfoKindLabel = basicInfoKindLabel
    
    basicInfoKindSelectButton.top(to: basicInfoKindLabel, offset: 4.0)
    
    //basicInfoAgeSelectButton
    let basicInfoAgeSelectButton = ANIImageButtonView()
    basicInfoAgeSelectButton.delegate = self
    basicInfoAgeSelectButton.image = UIImage(named: "basicInfoSelectButton")
    basicInfoBG.addSubview(basicInfoAgeSelectButton)
    basicInfoAgeSelectButton.width(10.0)
    basicInfoAgeSelectButton.height(10.0)
    basicInfoAgeSelectButton.rightToSuperview(offset: -10.0)
    self.basicInfoAgeSelectButton = basicInfoAgeSelectButton
    
    //basicInfoAgeLabel
    let basicInfoAgeLabel = UILabel()
    basicInfoAgeLabel.text = "年齢：選択"
    basicInfoAgeLabel.font = UIFont.systemFont(ofSize: 15.0)
    basicInfoAgeLabel.textColor = ANIColor.dark
    basicInfoAgeLabel.numberOfLines = 0
    basicInfoAgeLabel.isUserInteractionEnabled = true
    let tapAgeGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ageSelectButtonTapped))
    basicInfoAgeLabel.addGestureRecognizer(tapAgeGestureRecognizer)
    basicInfoBG.addSubview(basicInfoAgeLabel)
    basicInfoAgeLabel.topToSuperview(offset: 10.0)
    basicInfoAgeLabel.leftToRight(of: basicInfoLine, offset: 10.0)
    basicInfoAgeLabel.rightToLeft(of: basicInfoAgeSelectButton, offset: -10)
    self.basicInfoAgeLabel = basicInfoAgeLabel
    
    basicInfoAgeSelectButton.top(to: basicInfoAgeLabel, offset: 4.0)
    
    //basicInfoSexSelectButton
    let basicInfoSexSelectButton = ANIImageButtonView()
    basicInfoSexSelectButton.delegate = self
    basicInfoSexSelectButton.image = UIImage(named: "basicInfoSelectButton")
    basicInfoBG.addSubview(basicInfoSexSelectButton)
    basicInfoSexSelectButton.width(10.0)
    basicInfoSexSelectButton.height(10.0)
    basicInfoSexSelectButton.rightToLeft(of: basicInfoLine, offset: -10.0)
    self.basicInfoSexSelectButton = basicInfoSexSelectButton
    
    //basicInfoSexLabel
    let basicInfoSexLabel = UILabel()
    basicInfoSexLabel.text = "性別：選択"
    basicInfoSexLabel.font = UIFont.systemFont(ofSize: 15.0)
    basicInfoSexLabel.textColor = ANIColor.dark
    basicInfoSexLabel.numberOfLines = 0
    basicInfoSexLabel.isUserInteractionEnabled = true
    let tapSexGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(sexSelectButtonTapped))
    basicInfoSexLabel.addGestureRecognizer(tapSexGestureRecognizer)
    basicInfoBG.addSubview(basicInfoSexLabel)
    basicInfoSexLabel.topToBottom(of: basicInfoKindLabel, offset: 10.0)
    basicInfoSexLabel.leftToSuperview(offset: 10.0)
    basicInfoSexLabel.rightToLeft(of: basicInfoSexSelectButton, offset: -10.0)
    self.basicInfoSexLabel = basicInfoSexLabel
    
    basicInfoSexSelectButton.top(to: basicInfoSexLabel, offset: 4.0)
    
    //basicInfoHomeSelectButton
    let basicInfoHomeSelectButton = ANIImageButtonView()
    basicInfoHomeSelectButton.delegate = self
    basicInfoHomeSelectButton.image = UIImage(named: "basicInfoSelectButton")
    basicInfoBG.addSubview(basicInfoHomeSelectButton)
    basicInfoHomeSelectButton.width(10.0)
    basicInfoHomeSelectButton.height(10.0)
    basicInfoHomeSelectButton.rightToSuperview(offset: -10.0)
    self.basicInfoHomeSelectButton = basicInfoHomeSelectButton
    
    //basicInfoHomeLabel
    let basicInfoHomeLabel = UILabel()
    basicInfoHomeLabel.text = "お家：選択"
    basicInfoHomeLabel.font = UIFont.systemFont(ofSize: 15.0)
    basicInfoHomeLabel.textColor = ANIColor.dark
    basicInfoHomeLabel.numberOfLines = 0
    basicInfoHomeLabel.isUserInteractionEnabled = true
    let tapHomeGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(homeSelectButtonTapped))
    basicInfoHomeLabel.addGestureRecognizer(tapHomeGestureRecognizer)
    basicInfoBG.addSubview(basicInfoHomeLabel)
    basicInfoHomeLabel.topToBottom(of: basicInfoAgeLabel, offset: 10.0)
    basicInfoHomeLabel.leftToRight(of: basicInfoLine, offset: 10.0)
    basicInfoHomeLabel.rightToLeft(of: basicInfoHomeSelectButton ,offset: -10.0)
    self.basicInfoHomeLabel = basicInfoHomeLabel
    
    basicInfoHomeSelectButton.top(to: basicInfoHomeLabel, offset: 4.0)
    
    //basicInfoVaccineSelectButton
    let basicInfoVaccineSelectButton = ANIImageButtonView()
    basicInfoVaccineSelectButton.delegate = self
    basicInfoVaccineSelectButton.image = UIImage(named: "basicInfoSelectButton")
    basicInfoBG.addSubview(basicInfoVaccineSelectButton)
    basicInfoVaccineSelectButton.width(10.0)
    basicInfoVaccineSelectButton.height(10.0)
    basicInfoVaccineSelectButton.rightToLeft(of: basicInfoLine, offset: -10.0)
    self.basicInfoVaccineSelectButton = basicInfoVaccineSelectButton
    
    //basicInfoVaccineLabel
    let basicInfoVaccineLabel = UILabel()
    basicInfoVaccineLabel.text = "ワクチン：選択"
    basicInfoVaccineLabel.font = UIFont.systemFont(ofSize: 15.0)
    basicInfoVaccineLabel.textColor = ANIColor.dark
    basicInfoVaccineLabel.numberOfLines = 0
    basicInfoVaccineLabel.isUserInteractionEnabled = true
    let tapVaccineGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(vaccineSelectButtonTapped))
    basicInfoVaccineLabel.addGestureRecognizer(tapVaccineGestureRecognizer)
    basicInfoBG.addSubview(basicInfoVaccineLabel)
    basicInfoVaccineLabel.topToBottom(of: basicInfoSexLabel, offset: 10.0)
    basicInfoVaccineLabel.leftToSuperview(offset: 10.0)
    basicInfoVaccineLabel.rightToLeft(of: basicInfoVaccineSelectButton, offset: 10.0)
    basicInfoVaccineLabel.bottomToSuperview(offset: -10)
    self.basicInfoVaccineLabel = basicInfoVaccineLabel
    
    basicInfoVaccineSelectButton.top(to: basicInfoVaccineLabel, offset: 4.0)
    
    //basicInfoCastrationSelectButton
    let basicInfoCastrationSelectButton = ANIImageButtonView()
    basicInfoCastrationSelectButton.delegate = self
    basicInfoCastrationSelectButton.image = UIImage(named: "basicInfoSelectButton")
    basicInfoBG.addSubview(basicInfoCastrationSelectButton)
    basicInfoCastrationSelectButton.width(10.0)
    basicInfoCastrationSelectButton.height(10.0)
    basicInfoCastrationSelectButton.rightToSuperview(offset: -10.0)
    self.basicInfoCastrationSelectButton = basicInfoCastrationSelectButton
    
    //basicInfoCastrationLabel
    let basicInfoCastrationLabel = UILabel()
    basicInfoCastrationLabel.text = "去勢：選択"
    basicInfoCastrationLabel.font = UIFont.systemFont(ofSize: 15.0)
    basicInfoCastrationLabel.textColor = ANIColor.dark
    basicInfoCastrationLabel.numberOfLines = 0
    basicInfoCastrationLabel.isUserInteractionEnabled = true
    let tapCastrationGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(castrationSelectButtonTapped))
    basicInfoCastrationLabel.addGestureRecognizer(tapCastrationGestureRecognizer)
    basicInfoBG.addSubview(basicInfoCastrationLabel)
    basicInfoCastrationLabel.topToBottom(of: basicInfoHomeLabel, offset: 10.0)
    basicInfoCastrationLabel.leftToRight(of: basicInfoLine, offset: 10.0)
    basicInfoCastrationLabel.rightToLeft(of: basicInfoCastrationSelectButton, offset: -10.0)
    self.basicInfoCastrationLabel = basicInfoCastrationLabel
    
    basicInfoCastrationSelectButton.top(to: basicInfoCastrationLabel, offset: 4.0)
    
    //reasonTitleLabel
    let reasonTitleLabel = UILabel()
    reasonTitleLabel.font = UIFont.boldSystemFont(ofSize: 20.0)
    reasonTitleLabel.textColor = ANIColor.dark
    reasonTitleLabel.text = "募集する理由"
    contentView.addSubview(reasonTitleLabel)
    reasonTitleLabel.topToBottom(of: basicInfoBG, offset: CONTENT_SPACE)
    reasonTitleLabel.leftToSuperview(offset: 10.0)
    reasonTitleLabel.rightToSuperview(offset: -10.0)
    self.reasonTitleLabel = reasonTitleLabel
    
    //reasonBG
    let reasonBG = UIView()
    reasonBG.backgroundColor = ANIColor.lightGray
    reasonBG.layer.cornerRadius = 10.0
    reasonBG.layer.masksToBounds = true
    contentView.addSubview(reasonBG)
    reasonBG.topToBottom(of: reasonTitleLabel, offset: 10.0)
    reasonBG.leftToSuperview(offset: 10.0)
    reasonBG.rightToSuperview(offset: -10.0)
    self.reasonBG = reasonBG
    
    //reasonTextView
    let reasonTextView = ANIPlaceHolderTextView()
    reasonTextView.font = UIFont.systemFont(ofSize: 15.0)
    reasonTextView.textColor = ANIColor.dark
    reasonTextView.backgroundColor = .clear
    reasonTextView.isScrollEnabled = false
    reasonTextView.placeHolder = "理由を入力いてください"
    reasonTextView.delegate = self
    reasonBG.addSubview(reasonTextView)
    let insets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0)
    reasonTextView.edgesToSuperview(insets: insets)
    self.reasonTextView = reasonTextView
    setHideButtonOnKeyboard(textView: reasonTextView)
    
    //introduceTitleLabel
    let introduceTitleLabel = UILabel()
    introduceTitleLabel.font = UIFont.boldSystemFont(ofSize: 20.0)
    introduceTitleLabel.textColor = ANIColor.dark
    introduceTitleLabel.text = "猫ちゃんの紹介"
    contentView.addSubview(introduceTitleLabel)
    introduceTitleLabel.topToBottom(of: reasonBG, offset: CONTENT_SPACE)
    introduceTitleLabel.leftToSuperview(offset: 10.0)
    introduceTitleLabel.rightToSuperview(offset: -10.0)
    self.introduceTitleLabel = introduceTitleLabel
    
    //introduceBG
    let introduceBG = UIView()
    introduceBG.backgroundColor = ANIColor.lightGray
    introduceBG.layer.cornerRadius = 10.0
    introduceBG.layer.masksToBounds = true
    contentView.addSubview(introduceBG)
    introduceBG.topToBottom(of: introduceTitleLabel, offset: 10.0)
    introduceBG.leftToSuperview(offset: 10.0)
    introduceBG.rightToSuperview(offset: -10.0)
    self.introduceBG = introduceBG
    
    //introduceTextView
    let introduceTextView = ANIPlaceHolderTextView()
    introduceTextView.font = UIFont.systemFont(ofSize: 15.0)
    introduceTextView.textColor = ANIColor.dark
    introduceTextView.isScrollEnabled = false
    introduceTextView.backgroundColor = .clear
    introduceTextView.placeHolder = "可愛いところを伝えましょう*^-^*"
    introduceTextView.delegate = self
    introduceBG.addSubview(introduceTextView)
    introduceTextView.edgesToSuperview(insets: insets)
    self.introduceTextView = introduceTextView
    setHideButtonOnKeyboard(textView: introduceTextView)
    
    //introduceImagesView
    let introduceImagesView = ANIRecruitContributionImagesView()
    introduceImagesView.delegate = self
    contentView.addSubview(introduceImagesView)
    introduceImagesView.topToBottom(of: introduceBG, offset: 10.0)
    introduceImagesView.leftToSuperview()
    introduceImagesView.rightToSuperview()
    introduceImagesView.height(UIScreen.main.bounds.width * INTRODUCE_IMAGES_VIEW_RATIO)
    self.introduceImagesView = introduceImagesView
    
    //passingTitleLabel
    let passingTitleLabel = UILabel()
    passingTitleLabel.font = UIFont.boldSystemFont(ofSize: 20.0)
    passingTitleLabel.textColor = ANIColor.dark
    passingTitleLabel.text = "引渡し方法"
    contentView.addSubview(passingTitleLabel)
    passingTitleLabel.topToBottom(of: introduceImagesView, offset: CONTENT_SPACE)
    passingTitleLabel.leftToSuperview(offset: 10.0)
    self.passingTitleLabel = passingTitleLabel
    
    //passingSubTitleLabel
    let passingSubTitleLabel = UILabel()
    passingSubTitleLabel.text = "*必ず手渡し"
    passingSubTitleLabel.font = UIFont.systemFont(ofSize: 12.0)
    passingSubTitleLabel.textColor = ANIColor.subTitle
    contentView.addSubview(passingSubTitleLabel)
    passingSubTitleLabel.leftToRight(of: passingTitleLabel, offset: 5.0)
    passingSubTitleLabel.rightToSuperview(offset: -10.0)
    passingSubTitleLabel.bottom(to: passingTitleLabel, offset: -2.0)
    self.passingSubTitleLabel = passingSubTitleLabel
    
    //passingBG
    let passingBG = UIView()
    passingBG.backgroundColor = ANIColor.lightGray
    passingBG.layer.cornerRadius = 10.0
    passingBG.layer.masksToBounds = true
    contentView.addSubview(passingBG)
    passingBG.topToBottom(of: passingTitleLabel, offset: 10.0)
    passingBG.leftToSuperview(offset: 10.0)
    passingBG.rightToSuperview(offset: -10.0)
    passingBG.bottomToSuperview(offset: -15.0 - 10.0 - ANIRecruitContributionViewController.CONTRIBUTE_BUTTON_HEIGHT)
    self.passingBG = passingBG
    
    //passingTextView
    let passingTextView = ANIPlaceHolderTextView()
    passingTextView.font = UIFont.systemFont(ofSize: 15.0)
    passingTextView.textColor = ANIColor.dark
    passingTextView.backgroundColor = .clear
    passingTextView.isScrollEnabled = false
    passingTextView.placeHolder = "引渡し方法を入力してください"
    passingTextView.delegate = self
    passingBG.addSubview(passingTextView)
    passingTextView.edgesToSuperview(insets: insets)
    self.passingTextView = passingTextView
    setHideButtonOnKeyboard(textView: passingTextView)
    
    //activityIndicatorView
    let activityIndicatorView = ANIActivityIndicator()
    activityIndicatorView.isFull = false
    self.addSubview(activityIndicatorView)
    activityIndicatorView.edgesToSuperview()
    self.activityIndicatorView = activityIndicatorView
  }
  
  private func reloadLayout() {
    guard let recruit = self.recruit,
          let titleTextView = self.titleTextView,
          let basicInfoKindLabel = self.basicInfoKindLabel,
          let basicInfoAgeLabel = self.basicInfoAgeLabel,
          let basicInfoSexLabel = self.basicInfoSexLabel,
          let basicInfoHomeLabel = self.basicInfoHomeLabel,
          let basicInfoVaccineLabel = self.basicInfoVaccineLabel,
          let basicInfoCastrationLabel = self.basicInfoCastrationLabel,
          let reasonTextView = self.reasonTextView,
          let introduceTextView = self.introduceTextView,
          let passingTextView = self.passingTextView else { return }
    
    titleTextView.text = recruit.title
    basicInfoKindLabel.text = "種類：" + recruit.kind
    basicInfoAgeLabel.text = "年齢：" + recruit.age
    basicInfoSexLabel.text = "性別：" + recruit.sex
    basicInfoHomeLabel.text = "お家：" + recruit.home
    basicInfoVaccineLabel.text = "ワクチン：" + recruit.vaccine
    basicInfoCastrationLabel.text = "去勢：" + recruit.castration
    reasonTextView.text = recruit.reason
    introduceTextView.text = recruit.introduce
    passingTextView.text = recruit.passing
  }
  
  private func setUIImageHeaderUrl(url: String, completion:(()->())? = nil) {
    if let url = URL(string: url) {
      let data = try? Data(contentsOf: url)
      
      if let imageData = data, let image = UIImage(data: imageData) {
        DispatchQueue.main.async {
          self.headerImage = image
        }
        completion?()
      }
    }
  }
  
  private func setUIImagesFromUrls(urls: [String], completion:(()->())? = nil) {
    var images = [UIImage?]()
    for introduceImageUrl in urls {
      if let url = URL(string: introduceImageUrl) {
        let data = try? Data(contentsOf: url)
        
        if let imageData = data, let image = UIImage(data: imageData) {
          images.append(image)
          
          if images.count == urls.count {
            DispatchQueue.main.async {
              self.introduceImages = images
            }
            completion?()
          }
        }
      }
    }
  }
  
  private func setNotification() {
    ANINotificationManager.receive(pickerViewDidSelect: self, selector: #selector(updateBasicInfo))
    ANINotificationManager.receive(keyboardWillChangeFrame: self, selector: #selector(keyboardWillChangeFrame))
  }
  
  private func setHideButtonOnKeyboard(textView: UITextView){
    let tools = UIToolbar()
    tools.tintColor = ANIColor.emerald
    tools.frame = CGRect(x: 0, y: 0, width: frame.width, height: KEYBOARD_HIDE_TOOL_BAR_HEIGHT)
    let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
    let closeButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(keyboardHideButtonTapped))
    tools.items = [spacer, closeButton]
    textView.inputAccessoryView = tools
  }
  
  func getRecruitInfo() -> RecruitInfo? {
    guard let headerImage = self.headerImage,
          let titleTextView = self.titleTextView,
          let basicInfoKindLabel = self.basicInfoKindLabel,
          let kindText = basicInfoKindLabel.text,
          let basicInfoAgeLabel = self.basicInfoAgeLabel,
          let ageText = basicInfoAgeLabel.text,
          let basicInfoSexLabel = self.basicInfoSexLabel,
          let sexText = basicInfoSexLabel.text,
          let basicInfoHomeLabel = self.basicInfoHomeLabel,
          let homeText = basicInfoHomeLabel.text,
          let basicInfoVaccineLabel = self.basicInfoVaccineLabel,
          let vaccineText = basicInfoVaccineLabel.text,
          let basicInfoCastrationLabel = self.basicInfoCastrationLabel,
          let castrationText = basicInfoCastrationLabel.text,
          let resonTextView = self.reasonTextView,
          let introduceTextView = self.introduceTextView,
          let passingTextView = self.passingTextView else { return nil }
    
    let kind = kindText.substring(3...) == "選択" ? "" : kindText.substring(3...)
    let age = ageText.substring(3...) == "選択" ? "" : ageText.substring(3...)
    let sex = sexText.substring(3...) == "選択" ? "" : sexText.substring(3...)
    let home = homeText.substring(3...) == "選択" ? "" : homeText.substring(3...)
    let vaccine = vaccineText.substring(5...) == "選択" ? "" : vaccineText.substring(5...)
    let castration = castrationText.substring(3...) == "選択" ? "" : castrationText.substring(3...)
    
    let recruitInfo = RecruitInfo(headerImage: headerImage, title: titleTextView.text, kind: kind, age: age, sex: sex, home: home, vaccine: vaccine, castration: castration, reason: resonTextView.text, introduce: introduceTextView.text, introduceImages: introduceImages, passing: passingTextView.text, isRecruit: true)
    
    return recruitInfo
  }
  
  @objc private func hideKeyboard() {
    self.endEditing(true)
  }
  
  //MARK: action
  @objc private func kindSelectButtonTapped() {
    self.endEditing(true)
    self.delegate?.kindSelectButtonTapped()
  }
  
  @objc private func ageSelectButtonTapped() {
    self.endEditing(true)
    self.delegate?.ageSelectButtonTapped()
  }
  
  @objc private func sexSelectButtonTapped() {
    self.endEditing(true)
    self.delegate?.sexSelectButtonTapped()
  }
  
  @objc private func homeSelectButtonTapped() {
    self.endEditing(true)
    self.delegate?.homeSelectButtonTapped()
  }
  
  @objc private func vaccineSelectButtonTapped() {
    self.endEditing(true)
    self.delegate?.vaccineSelectButtonTapped()
  }
  
  @objc private func castrationSelectButtonTapped() {
    self.endEditing(true)
    self.delegate?.castrationSelectButtonTapped()
  }
  
  @objc private func updateBasicInfo(_ notification: NSNotification) {
    guard let pickMode = self.pickMode,
          let basicInfoKindLabel = self.basicInfoKindLabel,
          let basicInfoAgeLabel = self.basicInfoAgeLabel,
          let basicInfoSexLabel = self.basicInfoSexLabel,
          let basicInfoHomeLabel = self.basicInfoHomeLabel,
          let basicInfoVaccineLabel = self.basicInfoVaccineLabel,
          let basicInfoCastrationLabel = self.basicInfoCastrationLabel,
          var pickItem = notification.object as? String else { return }

    if pickItem == "" {
      pickItem = "わからない"
    }
    
    switch pickMode {
    case .kind:
      basicInfoKindLabel.text = "種類：\(pickItem)"
    case .age:
      basicInfoAgeLabel.text = "年齢：\(pickItem)"
    case .sex:
      basicInfoSexLabel.text = "性別：\(pickItem)"
    case .home:
      basicInfoHomeLabel.text = "お家：\(pickItem)"
    case .vaccine:
      basicInfoVaccineLabel.text = "ワクチン：\(pickItem)"
    case .castration:
      basicInfoCastrationLabel.text = "去勢：\(pickItem)"
    }
  }
  
  @objc func keyboardHideButtonTapped(){
    self.endEditing(true)
    self.resignFirstResponder()
  }
  
  @objc func keyboardWillChangeFrame(_ notification: Notification) {
    guard let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
          let scrollView = self.scrollView,
          let selectedTextViewMaxY = self.selectedTextViewMaxY else { return }

    let selectedTextViewVisiableMaxY = selectedTextViewMaxY - scrollView.contentOffset.y
    
    if selectedTextViewVisiableMaxY > keyboardFrame.origin.y {
      let margin: CGFloat = 15.0
      let blindHeight = selectedTextViewVisiableMaxY - keyboardFrame.origin.y + margin
      scrollView.contentOffset.y = scrollView.contentOffset.y + blindHeight
    }
  }
}

//MARK: UIScrollViewDelegate
extension ANIRecruitContributionView: UIScrollViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard let imageView = self.headerImageView,
          let imageViewTopConstraint = self.headerImageViewTopConstraint,
          let headerMinHeight = self.headerMinHeight else { return }
    
    let headerImageViewHeight: CGFloat = UIScreen.main.bounds.width * UIViewController.HEADER_IMAGE_VIEW_RATIO

    let scrollY = scrollView.contentOffset.y
    let newScrollY = scrollY + headerImageViewHeight
    
    //imageView animation
    if newScrollY < 0 {
      let scaleRatio = 1 - newScrollY / headerImageViewHeight
      imageView.transform = CGAffineTransform(scaleX: scaleRatio, y: scaleRatio)
      imageViewTopConstraint.constant = 0
    }
    else {
      imageView.transform = CGAffineTransform.identity
      if headerImageViewHeight - newScrollY > headerMinHeight {
        imageViewTopConstraint.constant = -newScrollY
        self.layoutIfNeeded()
      } else {
        imageViewTopConstraint.constant = -(headerImageViewHeight - headerMinHeight)
        self.layoutIfNeeded()
      }
    }
    
    //navigation bar animation
    let offset = newScrollY / (headerImageViewHeight - headerMinHeight)
    self.delegate?.recruitContributeViewDidScroll(offset: offset)
  }
}

//MARK: ANIButtonViewDelegate
extension ANIRecruitContributionView: ANIButtonViewDelegate {
  func buttonViewTapped(view: ANIButtonView) {
    self.endEditing(true)
    
    if view === self.headerImagePickupButton {
      self.delegate?.imagePickButtonTapped()
    }
    if view === self.basicInfoKindSelectButton {
      self.delegate?.kindSelectButtonTapped()
    }
    if view === self.basicInfoAgeSelectButton {
      self.delegate?.ageSelectButtonTapped()
    }
    if view === self.basicInfoSexSelectButton {
      self.delegate?.sexSelectButtonTapped()
    }
    if view === self.basicInfoHomeSelectButton {
      self.delegate?.homeSelectButtonTapped()
    }
    if view === self.basicInfoVaccineSelectButton {
      self.delegate?.vaccineSelectButtonTapped()
    }
    if view === self.basicInfoCastrationSelectButton {
      self.delegate?.castrationSelectButtonTapped()
    }
  }
}

//MARK: UITextViewDelegate
extension ANIRecruitContributionView: UITextViewDelegate {
  func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
    guard let selectedTextViewSuperView = textView.superview else { return false }
    selectedTextViewMaxY = selectedTextViewSuperView.frame.maxY
    
    return true
  }
  
  func textViewDidEndEditing(_ textView: UITextView) {
    selectedTextViewMaxY = nil
  }
}

//MARK: ANIRecruitContributionImagesViewDelegate
extension ANIRecruitContributionView: ANIRecruitContributionImagesViewDelegate {
  func imagesPickCellTapped() {
    self.delegate?.imagesPickCellTapped()
  }
  
  func imageDelete(index: Int) {
    introduceImages.remove(at: index)
  }
}
