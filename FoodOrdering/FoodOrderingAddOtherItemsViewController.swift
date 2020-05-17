//
//  FoodOrderingAddOtherItemsViewController.swift
//  FoodOrdering
//
//  Created by fOrest on 2020/5/14.
//  Copyright © 2020 fOrest. All rights reserved.
//

import UIKit

protocol FoodOrderingAddOtherItemsViewControllerDelegate {
    
    func foodOrderingAddOtherItemsViewControllerConfrimed(sender: FoodOrderingAddOtherItemsViewController)
}

class FoodOrderingAddOtherItemsViewController : UIViewController {
    
    @IBOutlet weak var itemNameTextField: UITextField!
    
    @IBOutlet weak var itemPriceTextField: UITextField!
    
    @IBOutlet weak var itemNumberTextField: UITextField!
    
    @IBOutlet weak var itemNumberStepper: UIStepper!
    
    var currentOrderBill: OrderBillTable.OrderBill?
    
    var itemName: String? {
        
        get { return self.itemNameTextField.text ?? "未知"}
        set(value) { itemNumberTextField.text = value }
     }
    
    var itemPrice: Double? {
        get { return Double(self.itemPriceTextField.text ?? "0") }
        set(value) { self.itemPriceTextField.text = "\(value ?? 0)"}
    }
    
    var itemNumber: Int64? {
        get { return Int64(self.itemNumberStepper.value) }
        set(value) {
            
            self.itemNumberTextField.text = "\(value ?? 1)"
            self.itemNumberStepper.value = Double(value ?? 1)
        }
    }
    
    var delegate: FoodOrderingAddOtherItemsViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        itemNumberStepper.minimumValue = 1
        itemNumberStepper.value = 1
        
//        itemNumberStepper.setIncrementImage(UIImage(named: "stepper_plus"), for: UIControl.State.normal)
//        itemNumberStepper.setDecrementImage(UIImage(named: "stepper_minus"), for: UIControl.State.normal)
//        itemNumberStepper.setBackgroundImage(UIImage(named: "stepper_background"), for: UIControl.State.normal)
    }
    
    @IBAction func itemNumberStepperValueChanged(_ sender: Any) {
        
        itemNumberTextField.text = "\(itemNumberStepper.value)"
    }
    
    
    @IBAction func cancellButtonDidTouch(_ sender: Any) {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func confrimButtonDidTouch(_ sender: Any) {
        
        guard itemName != nil && itemName != "" else {
            
            AppDelegate.shared?.showAlertMessageWithActionOK(self, "商品名称不能为空！", nil)
            return
        }
        guard itemPrice != nil && itemPrice != 0 else {
            
            AppDelegate.shared?.showAlertMessageWithActionOK(self, "商品价格不能为0", nil)
            return
        }
        
        do {
            let orderItem = OrderItemTable.OrderItem(serial: -1, orderId: self.currentOrderBill!.id, itemId: nil, itemName: itemName!, remarks: nil, count: itemNumber!, price: itemPrice!, timestamp: Date().timeIntervalSince1970)
            
            if var values = orderItem.values {
                
                values.removeValue(forKey: OrderItemTable.OrderItem.CodingKeys.serial.rawValue)
                
                try AppDelegate.shared?.dbWrapper?.insert(into: OrderItemTable.self, with: values)
            }
            
        }catch {
            debugPrint(error.localizedDescription)
        }
        self.dismiss(animated: true) {
            
            self.delegate?.foodOrderingAddOtherItemsViewControllerConfrimed(sender: self)
        }
    }
    
}

