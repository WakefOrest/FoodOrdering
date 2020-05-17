//
//  FoodOrderingInputDialog.swift
//  FoodOrdering
//
//  Created by fOrest on 2020/5/5.
//  Copyright © 2020 fOrest. All rights reserved.
//

import UIKit
protocol  FoodOrderingInputDialogDelegate {
    
    func foodOrderingInputDialogConfirmed(_ sender: FoodOrderingInputDialog)
}

class FoodOrderingInputDialog: UIViewController {
    
    @IBOutlet weak var orderedNumberLabel: UILabel!
    
    @IBOutlet weak var foodNameLabel: UILabel!
    
    @IBOutlet weak var countingStepper: UIStepper!
    
    @IBOutlet weak var newOrderingNumberLabel: UILabel!
    
    var foodItem: MenuItemTable.MenuItem?
    
    var orderedNumber: Int64?
    
    var newOrderingNumber: Int64?
    
    var delegate: FoodOrderingInputDialogDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        foodNameLabel.text = foodItem?.name ?? "无商品名称"
        orderedNumberLabel.text = "\(orderedNumber ?? 0)"
        newOrderingNumberLabel.text = "\(newOrderingNumber ?? 0)"
        
        countingStepper.value = Double(newOrderingNumber ?? 0)
        countingStepper.minimumValue = Double((orderedNumber ?? 0) * -1)
        
        countingStepper.setIncrementImage(UIImage(named: "stepper_plus"), for: UIControl.State.normal)
        countingStepper.setDecrementImage(UIImage(named: "stepper_minus"), for: UIControl.State.normal)
        countingStepper.setBackgroundImage(UIImage(named: "stepper_background"), for: UIControl.State.normal)
        
        //countingStepper.transform = CGAffineTransform(scaleX: 3.0, y: 2.5)
    }
    
    
    @IBAction func stepperValueChanged(_ sender: Any) {
        
        newOrderingNumber = Int64(self.countingStepper.value)
        newOrderingNumberLabel.text = "\(newOrderingNumber!)"
    }
    
    
    @IBAction func cancellButtonTouched(_ sender: Any) {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func confirmButtonTouched(_ sender: Any) {
        
//        if newOrderingNumber == 0 {
//            
//            AppDelegate.shared?.showAlertMessageWithActionOK(self, "商品添加数量不能为零", nil)
//            return
//        }
        delegate?.foodOrderingInputDialogConfirmed(self)
        self.dismiss(animated: false, completion: nil)
    }
}
