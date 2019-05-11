//
//  ANIPopupOptionView.swift
//  Ani
//
//  Created by jeonminseop on 2018/07/26.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import TinyConstraints

protocol ANIPopupOptionViewDelegate {
  func cancelButtonTapped()
  func deleteContribution()
  func reportContribution()
  func optionTapped(index: Int)
}

class ANIPopupOptionView: UIView {
  
  private weak var optionAreaBG: UIView?
  private var optionTableViewHeightConstraint: Constraint?
  private weak var optionTableView: UITableView?
  
  private let BUTTON_HEIGHT: CGFloat = 50.0
  private weak var redButton: UIButton?
  private weak var cancelButton: UIButton?
  
  var isMe: Bool? {
    didSet {
      reloadRedButton()
    }
  }
  
  var options: [String]? {
    didSet {
      reloadOptionArea()
    }
  }

  var delegate: ANIPopupOptionViewDelegate?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    //cancelButton
    let cancelButton = UIButton()
    cancelButton.setTitle("キャンセル", for: .normal)
    cancelButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17.0)
    cancelButton.setTitleColor(ANIColor.dark, for: .normal)
    cancelButton.backgroundColor = .white
    cancelButton.layer.cornerRadius = 7.0
    cancelButton.layer.masksToBounds = true
    cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
    addSubview(cancelButton)
    cancelButton.edgesToSuperview(excluding: .top)
    cancelButton.height(BUTTON_HEIGHT)
    self.cancelButton = cancelButton
    
    //redButton
    let redButton = UIButton()
    redButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17.0)
    redButton.setTitleColor(ANIColor.red, for: .normal)
    redButton.backgroundColor = .white
    redButton.layer.cornerRadius = 7.0
    redButton.layer.masksToBounds = true
    redButton.addTarget(self, action: #selector(redButtonTapped), for: .touchUpInside)
    addSubview(redButton)
    redButton.edgesToSuperview(excluding: [.top, .bottom])
    redButton.bottomToTop(of: cancelButton, offset: -10.0)
    redButton.height(BUTTON_HEIGHT)
    self.redButton = redButton
    
    //optionAreaBG
    let optionAreaBG = UIView()
    optionAreaBG.backgroundColor = .white
    optionAreaBG.layer.cornerRadius = 7.0
    optionAreaBG.layer.masksToBounds = true
    optionAreaBG.isHidden = true
    addSubview(optionAreaBG)
    optionAreaBG.edgesToSuperview(excluding: [.bottom])
    optionAreaBG.bottomToTop(of: redButton, offset: -10.0)
    self.optionAreaBG = optionAreaBG
    
    //optionTableView
    let optionTableView = UITableView()
    optionTableView.isScrollEnabled = false
    optionTableView.separatorStyle = .none
    optionTableView.dataSource = self
    optionTableView.delegate = self
    let identifiler = NSStringFromClass(ANIPopupOptionViewCell.self)
    optionTableView.register(ANIPopupOptionViewCell.self, forCellReuseIdentifier: identifiler)
    optionAreaBG.addSubview(optionTableView)
    optionTableView.edgesToSuperview()
    optionTableViewHeightConstraint = optionTableView.height(0)
    self.optionTableView = optionTableView
  }
  
  private func reloadOptionArea() {
    guard let optionAreaBG = self.optionAreaBG,
          let optionTableView = self.optionTableView,
          let optionTableViewHeightConstraint = self.optionTableViewHeightConstraint else { return }
    
    if self.options != nil {
      optionAreaBG.isHidden = false
      optionTableView.reloadData()
      optionTableViewHeightConstraint.constant = optionTableView.contentSize.height
    }
  }
  
  private func reloadRedButton() {
    guard let isMe = self.isMe,
          let redButton = self.redButton else { return }
    
    if isMe {
      redButton.setTitle("削除", for: .normal)
    } else {
      redButton.setTitle("通報する", for: .normal)
    }
  }
  
  //MARK: action
  @objc private func cancel() {
    self.delegate?.cancelButtonTapped()
  }
  
  @objc private func redButtonTapped() {
    guard let isMe = self.isMe else { return }
    
    if isMe {
      self.delegate?.deleteContribution()
    } else {
      self.delegate?.reportContribution()
    }
  }
}

//MARK: UITableViewDataSource
extension ANIPopupOptionView: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if let options = self.options {
      return options.count
    } else {
      return 0
    }
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let identifiler = NSStringFromClass(ANIPopupOptionViewCell.self)
    let cell = tableView.dequeueReusableCell(withIdentifier: identifiler, for: indexPath) as! ANIPopupOptionViewCell
    
    if let options = self.options {
      cell.option = options[indexPath.row]
    }
    
    return cell
  }
}

//MARK: UITableViewDelegate
extension ANIPopupOptionView: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    self.delegate?.optionTapped(index: indexPath.row)
  }
}
