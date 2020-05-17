//
//  OrderBillTableViewCell.swift
//  FoodOrdering
//
//  Created by fOrest on 2020/2/11.
//  Copyright © 2020 fOrest. All rights reserved.
//

import Foundation
import UIKit

class TodaysOrdersTableViewCell: UITableViewCell {
    
    @IBOutlet weak var tableNameTextField: UITextField!
    
    @IBOutlet weak var totalMoneyTextField: UITextField!
    
    @IBOutlet weak var createTimeTextField: UITextField!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var orderStateLabel: UILabel!
    
    @IBOutlet weak var takeAwayTextField: UITextField!
    
    var tableName: String? {
        get {
            return self.tableNameTextField.text
        }
        set (value) {
            tableNameTextField.text = value
        }
    }
    
    var totalMoney: Double? {
        
        get {
            return Double(self.totalMoneyTextField.text ?? "")
        }
        set (value) {
            totalMoneyTextField.text = "\(value ?? 0.0)"
        }
    }
    
    var createTime: TimeInterval? {
        
        get {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return dateFormatter.date(from: createTimeTextField.text ?? "")?.timeIntervalSince1970
        }
        set(value) {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            createTimeTextField.text = dateFormatter.string(from: Date(timeIntervalSince1970: value ?? 0))
        }
    }
    
    var isTakeAway: Bool? {
        get { if let text = self.takeAwayTextField.text {
            if text != "" {
                return true
            } else { return false }
        } else {return false }
        }
        set(value) {
            self.takeAwayTextField.text = (value ?? false ) ? "打包" : ""
        }
    }
    
    
    func setCollectionViewDataSourceDelegate(_ dataSourceDelegate: UICollectionViewDataSource & UICollectionViewDelegate, at indexPath: IndexPath) {
        collectionView.delegate = dataSourceDelegate
        collectionView.dataSource = dataSourceDelegate
        collectionView.tag = indexPath.row
        collectionView.reloadData()
    }
    
    private var selectedBackgroundAlpha: CGFloat { return 0.3 }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        selectedBackgroundView?.alpha = selectedBackgroundAlpha
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        selectedBackgroundView?.alpha = selectedBackgroundAlpha
    }
    
}

class OrdersItemsCell: UICollectionViewCell {
    
    @IBOutlet weak var orderItemImageView: UIImageView!
    
    @IBOutlet weak var itemNameTextField: UITextField!
    
    @IBOutlet weak var itemNumberTextField: UITextField!
}
