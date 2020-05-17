//
//  NewOrderViewController.swift
//  FoodOrdering
//
//  Created by fOrest on 2020/4/18.
//  Copyright © 2020 fOrest. All rights reserved.
//

import Foundation
import UIKit

protocol FoodOrderingNewOrderDialogDelegate {
    
    func foodOrderingNewOrderDialogConfirm(_ controller: FoodOrderingNewOrderDialog)
    func foodOrderingNewOrderDialogCancell(_ controller: FoodOrderingNewOrderDialog)
}

class FoodOrderingNewOrderDialog: UIViewController {
    
    @IBOutlet weak var tableNoTextField: UITextField!
    
    @IBOutlet weak var tableRemarksTextField: UITextField!
    
    @IBOutlet weak var tableNameTextField: UITextField!
    
    @IBOutlet weak var takeAwaySwitch: UISwitch!
    
    var currentOrderBill: OrderBillTable.OrderBill?
    
    var delegate: FoodOrderingNewOrderDialogDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let orderBill = self.currentOrderBill {
            
            self.tableNoTextField.text = orderBill.tableNO == nil ? nil : "\(orderBill.tableNO ?? 0)"
            self.tableRemarksTextField.text = orderBill.remarks
            self.tableNameTextField.text = orderBill.name
            self.takeAwaySwitch.isOn = orderBill.takeAway
        }
        
        takeAwaySwitch.transform = CGAffineTransform(scaleX: 2.0, y: 2.0)
    }
    
    @IBAction func cancellDidTouch(_ sender: Any) {
        
        dismiss(animated: true) {
            self.delegate?.foodOrderingNewOrderDialogCancell(self)
        }
    }
    
    @IBAction func confirmDidTouch(_ sender: Any) {
        
        if self.currentOrderBill == nil {
            
            self.currentOrderBill = OrderBillTable.OrderBill(id: -1, name: self.tableNameTextField.text, tableNO: Int64(self.tableNoTextField.text ?? "") ?? 0, remarks: self.tableRemarksTextField.text, createStamp: Date().timeIntervalSince1970, finishStamp: nil, finished: false, cancelled: false, takeAway: self.takeAwaySwitch.isOn, dilivery: false)
        } else {
            
            self.currentOrderBill?.tableNO = Int64(self.tableNoTextField.text ?? "") ?? 0
            self.currentOrderBill?.name = self.tableNameTextField.text
            self.currentOrderBill?.remarks = self.tableRemarksTextField.text
            self.currentOrderBill?.takeAway = self.takeAwaySwitch.isOn
        }
        
        dismiss(animated: false) {
            self.delegate?.foodOrderingNewOrderDialogConfirm(self)
        }
    }
    
}
