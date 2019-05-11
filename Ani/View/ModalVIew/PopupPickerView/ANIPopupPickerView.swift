//
//  ANIPopupPickerView.swift
//  Ani
//
//  Created by jeonminseop on 2018/05/15.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

protocol ANIPopupPickerViewDelegate {
  func okeyButtonTapped()
}

class ANIPopupPickerView: UIView {
  
  private weak var pickerAreaBG: UIView?
  private weak var pickerView: UIPickerView?
  
  private let OKEY_BUTTON_HEIGHT: CGFloat = 50.0
  private weak var okeyButton: UIButton?
  
  var pickerItem: [String]? {
    didSet {
      guard let pickerItem = self.pickerItem else { return }
      
      setupPickerView()
      if !pickerItem.isEmpty {
        pickItem = pickerItem[0]
      }
    }
  }
  
  private var pickItem: String = ""
  
  var delegate: ANIPopupPickerViewDelegate?

  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    //okeyButton
    let okeyButton = UIButton()
    okeyButton.setTitle("OK", for: .normal)
    okeyButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17.0)
    okeyButton.setTitleColor(ANIColor.dark, for: .normal)
    okeyButton.backgroundColor = .white
    okeyButton.layer.cornerRadius = 7.0
    okeyButton.layer.masksToBounds = true
    okeyButton.addTarget(self, action: #selector(okey), for: .touchUpInside)
    addSubview(okeyButton)
    okeyButton.edgesToSuperview(excluding: .top)
    okeyButton.height(OKEY_BUTTON_HEIGHT)
    self.okeyButton = okeyButton
    
    //pickerAreaBG
    let pickerAreaBG = UIView()
    pickerAreaBG.backgroundColor = .white
    pickerAreaBG.layer.cornerRadius = 7.0
    pickerAreaBG.layer.masksToBounds = true
    addSubview(pickerAreaBG)
    pickerAreaBG.edgesToSuperview(excluding: .bottom)
    pickerAreaBG.bottomToTop(of: okeyButton, offset: -10.0)
    self.pickerAreaBG = pickerAreaBG
  }
  
  private func setupPickerView() {
    guard let pickerAreaBG = self.pickerAreaBG else { return }
    
    let pickerView = UIPickerView()
    pickerView.dataSource = self
    pickerView.delegate = self
    pickerAreaBG.addSubview(pickerView)
    pickerView.edgesToSuperview()
    self.pickerView = pickerView
  }
  
  //MARK: action
  @objc private func okey() {
    self.delegate?.okeyButtonTapped()
    ANINotificationManager.postPickerViewDidSelect(pickItem: pickItem)
  }
}

//MARK: UIPickerViewDataSource
extension ANIPopupPickerView: UIPickerViewDataSource {
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }
  
  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    guard let pickerItem = self.pickerItem else { return 0 }
    return pickerItem.count
  }
  
  func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
    guard let pickerItem = self.pickerItem else { return nil }
    
    let title = pickerItem[row]
    return NSAttributedString(string: title, attributes: [.foregroundColor: ANIColor.dark])
  }
  
  func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
    return 30.0
  }
}

//MARK: UIPickerViewDelegate
extension ANIPopupPickerView: UIPickerViewDelegate {
  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    guard let pickerItem = self.pickerItem else { return "" }

    return pickerItem[row]
  }
  
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    guard let pickerItem = self.pickerItem else { return }

    pickItem = pickerItem[row]
  }
}
