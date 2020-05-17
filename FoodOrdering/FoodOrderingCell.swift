//
//  OrderItemsCell.swift
//  FoodOrdering
//
//  Created by fOrest on 2020/4/25.
//  Copyright © 2020 fOrest. All rights reserved.
//

import UIKit

class FoodOrderingCell: UICollectionViewCell {
    
    @IBOutlet weak var backgroudImageView: UIImageView!
    
    @IBOutlet weak var orderedNumberBackgroundImageView: UIImageView!
    
    @IBOutlet weak var orderingNumberBackgroundImageView: UIImageView!
    
    @IBOutlet weak var foodNameTextFieldNormal: UITextField!
            
    @IBOutlet weak var orderingNumberTextField: UITextField!
    
    @IBOutlet weak var orderedNumberTextField: UITextField!
    
    var orderedNumber: Int64?
    
    var orderingNumber: Int64?
    
    var foodItem: MenuItemTable.MenuItem?
    
}

class FoodOrderingHeaderView: UICollectionReusableView {
    
    @IBOutlet weak var headerLabel: UILabel!
}
