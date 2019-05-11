//
//  ANIOptionView.swift
//  Ani
//
//  Created by jeonminseop on 2018/06/22.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

protocol ANIOptionViewDelegate {
  func logoutTapped()
}

class ANIOptionView: UIView {
  
  private weak var tableView: UITableView?
  
  private var account = ["ログアウト"]
  
  var delegate: ANIOptionViewDelegate?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    let tableView = UITableView()
    let id = NSStringFromClass(ANIOptionViewCell.self)
    tableView.register(ANIOptionViewCell.self, forCellReuseIdentifier: id)
    tableView.dataSource = self
    tableView.delegate = self
    addSubview(tableView)
    tableView.edgesToSuperview()
    self.tableView = tableView
  }
}

//MARK: UITableViewDataSource
extension ANIOptionView: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return account.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let id = NSStringFromClass(ANIOptionViewCell.self)
    let cell = tableView.dequeueReusableCell(withIdentifier: id, for: indexPath) as! ANIOptionViewCell

    cell.titleLabel?.text = account[indexPath.row]
    
    return cell
  }
}

//MARK: UITableViewDelegate
extension ANIOptionView: UITableViewDelegate {
  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let headerView = UIView()
    headerView.backgroundColor = ANIColor.bg
    
    let titleLabel = UILabel()
    titleLabel.textColor = ANIColor.dark
    titleLabel.font = UIFont.boldSystemFont(ofSize: 15.0)
    headerView.addSubview(titleLabel)
    let insets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
    titleLabel.edgesToSuperview(insets: insets)
    
    titleLabel.text = "アカウント"
    
    return headerView
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if account[indexPath.row] == "ログアウト" {
      self.delegate?.logoutTapped()
    }
  }
}
