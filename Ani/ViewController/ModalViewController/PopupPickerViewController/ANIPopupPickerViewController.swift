//
//  ANIPopupPickerViewController.swift
//  Ani
//
//  Created by jeonminseop on 2018/05/15.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import TinyConstraints

class ANIPopupPickerViewController: UIViewController {
  
  private let POPUP_PICKER_VIEW_HEIGHT: CGFloat = 250.0
  private var popupPickerViewTopConstraintConstant: CGFloat?
  private weak var popupPickerViewTopConstratint: Constraint?
  private weak var popupPickerView: ANIPopupPickerView?
  
  var pickerItem: [String]?
  
  override func viewDidLoad() {
    setup()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    pickerViewPop()
  }
  
  private func setup() {
    //basic
    let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(pickerViewDismiss))
    self.view.addGestureRecognizer(tapGestureRecognizer)
    
    //popupPickerView
    let popupPickerView = ANIPopupPickerView()
    popupPickerView.pickerItem = pickerItem
    popupPickerView.delegate = self
    self.view.addSubview(popupPickerView)
    popupPickerViewTopConstratint = popupPickerView.topToBottom(of: self.view)
    popupPickerViewTopConstraintConstant = popupPickerViewTopConstratint?.constant
    popupPickerView.leftToSuperview(offset: 10.0)
    popupPickerView.rightToSuperview(offset: -10.0)
    popupPickerView.height(POPUP_PICKER_VIEW_HEIGHT)
    self.popupPickerView = popupPickerView
  }
  
  private func pickerViewPop() {
    guard let popupPickerViewTopConstratint = self.popupPickerViewTopConstratint,
          let window = UIApplication.shared.keyWindow else { return }
    
    let bottomSafeArea = window.safeAreaInsets.bottom
    let bottomMargin: CGFloat = 10.0
    popupPickerViewTopConstratint.constant = -(POPUP_PICKER_VIEW_HEIGHT + bottomSafeArea + bottomMargin)
    
    UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseInOut, animations: {
      self.view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
      self.view.layoutIfNeeded()
    }, completion: nil)
  }
  
  @objc private func pickerViewDismiss() {
    guard let popupPickerViewTopConstratint = self.popupPickerViewTopConstratint,
          let popupPickerViewTopConstraintConstant = self.popupPickerViewTopConstraintConstant else { return }

    popupPickerViewTopConstratint.constant = popupPickerViewTopConstraintConstant
    
    UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseInOut, animations: {
      self.view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.0)
      self.view.layoutIfNeeded()
    }, completion: { (complete) in
      self.dismiss(animated: false, completion: nil)
    })
  }
}

//ANIPopupPickerViewDelegate
extension ANIPopupPickerViewController: ANIPopupPickerViewDelegate {
  func okeyButtonTapped() {
    pickerViewDismiss()
  }
}
