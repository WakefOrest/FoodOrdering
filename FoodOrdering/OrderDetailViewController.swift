//
//  OrderDetailViewController.swift
//  FoodOrdering
//
//  Created by fOrest on 2020/4/26.
//  Copyright © 2020 fOrest. All rights reserved.
//

import UIKit

class OrderDetailViewController: UITableViewController, FoodOrderingViewControllerDelegate, FoodOrderingAddOtherItemsViewControllerDelegate, FoodOrderingNewOrderDialogDelegate {
    
    @IBOutlet weak var summaryDetailSegment: UISegmentedControl!
    
    @IBOutlet weak var addOtherItemsButton: UIBarButtonItem!
        
    var currentOrderBill: OrderBillTable.OrderBill?
    
    var orderItems: [OrderItemTable.OrderItem]?
    
    var orderItemsSum: [OrderItemTable.OrderItem]?
    
    func reloadData() {
        
        do {
            if let orderBill = self.currentOrderBill {
                
                self.orderItems = try AppDelegate.shared?.dbWrapper?.readOrderItems(by: orderBill.id)
                
                if let orderItems = self.orderItems {
                    
                    self.orderItemsSum = [OrderItemTable.OrderItem]()
                    
                    for item in orderItems {
                        
                        if orderItemsSum!.contains(where: { (orderItem) -> Bool in
                            if orderItem.itemId != nil && orderItem.itemId == item.itemId { return true } else { return false }
                        }) {
                            for index in 0..<orderItemsSum!.count where orderItemsSum![index].itemId == item.itemId {
                                
                                orderItemsSum![index].count = orderItemsSum![index].count + item.count
                            }
                        } else { orderItemsSum!.append(item) }
                    }
                } else { self.orderItemsSum = nil }
            } else { self.orderItems = nil; self.orderItemsSum = nil }
        } catch {
            
            AppDelegate.shared?.showAlertMessageWithActionOK(self, "错误提示", error.localizedDescription)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        summaryDetailSegment.selectedSegmentIndex = 0
        summaryDetailSegment.setTitleTextAttributes([NSAttributedString.Key.font : UIFont.systemFont(ofSize: 36)], for: .normal)
        summaryDetailSegment.frame = CGRect(x: summaryDetailSegment.frame.minX, y: summaryDetailSegment.frame.minY - 5, width: summaryDetailSegment.frame.width, height: summaryDetailSegment.frame.height + 5)
        addOtherItemsButton.setTitleTextAttributes([NSAttributedString.Key.font : UIFont.systemFont(ofSize: 36)], for: .normal)
        
        self.reloadData()
    }
    
        
    @IBAction func summaryDetailSegmentValueChanged(_ sender: Any) {
        
        self.tableView.reloadData()
    }
    
    func foodOrderingViewControllerOrderItemsSaved(_ sender: FoodOrderingViewController) {
        
        self.reloadData()
        self.tableView.reloadData()
        
        //AppDelegate.shared?.showAlertMessageAutoDismiss(self, "菜品添加成功！", nil, dismissAfter: DispatchTime.now() + 0.8)
    }
    
    @IBAction func deleteOrderButtonDidTouch(_ sender: Any) {
                
        let alert = UIAlertController(title: "提示", message: "确定要删除订单吗？", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "取消", style: UIAlertAction.Style.default, handler: nil))
        alert.addAction(UIAlertAction(title: "删除", style: UIAlertAction.Style.destructive){ (action) in
            
            do {
                try AppDelegate.shared?.dbWrapper?.delete(from: OrderItemTable.self, where: [OrderItemTable.OrderItem.CodingKeys.orderId.rawValue: self.currentOrderBill!.id])
                try AppDelegate.shared?.dbWrapper?.delete(from: OrderBillTable.self, where: [OrderBillTable.OrderBill.CodingKeys.id.rawValue: self.currentOrderBill!.id])
                
                self.navigationController?.popViewController(animated: true)
            }catch {
                
                AppDelegate.shared?.showAlertMessageWithActionOK(self, "错误提示", error.localizedDescription)
            }
        })
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func finishOrderButtonDidTouch(_ sender: Any) {
        
        let alert = UIAlertController(title: "提示", message: "确定要完成订单吗？", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "取消", style: UIAlertAction.Style.default, handler: nil))
        alert.addAction(UIAlertAction(title: "确定", style: UIAlertAction.Style.default){ (action) in
            
            do {
                try AppDelegate.shared?.dbWrapper?.update(OrderBillTable.self, with: [OrderBillTable.OrderBill.CodingKeys.finishStamp.rawValue: Date().timeIntervalSince1970, OrderBillTable.OrderBill.CodingKeys.finished.rawValue: true
                ], where: [OrderBillTable.OrderBill.CodingKeys.id.rawValue: self.currentOrderBill!.id])
                
                self.currentOrderBill = try AppDelegate.shared?.dbWrapper?.readOrderBillByOrderId(orderId: self.currentOrderBill!.id)
                
                self.navigationController?.popViewController(animated: true)
                
                //AppDelegate.shared?.showAlertMessageAutoDismiss(self, "订单已完成！", nil, dismissAfter: DispatchTime.now() + 0.8)
                
                
            }catch {
                
                AppDelegate.shared?.showAlertMessageWithActionOK(self, "错误提示", error.localizedDescription)
            }
        })
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func cancellOrderButtonDidTouch(_ sender: Any) {
        
        let alert = UIAlertController(title: "提示", message: "确定要取消订单吗？", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "取消", style: UIAlertAction.Style.default, handler: nil))
        alert.addAction(UIAlertAction(title: "确定", style: UIAlertAction.Style.default){ (action) in
            
            do {
                try AppDelegate.shared?.dbWrapper?.update(OrderBillTable.self, with: [ OrderBillTable.OrderBill.CodingKeys.cancelled.rawValue: true
                ], where: [OrderBillTable.OrderBill.CodingKeys.id.rawValue: self.currentOrderBill!.id])
                
                self.currentOrderBill = try AppDelegate.shared?.dbWrapper?.readOrderBillByOrderId(orderId: self.currentOrderBill!.id)
                
                //self.tableView.reloadData()
                self.navigationController?.popViewController(animated: true)
                
                //AppDelegate.shared?.showAlertMessageAutoDismiss(self, "订单已取消！", nil, dismissAfter: DispatchTime.now() + 0.8)
                
            }catch {
                
                AppDelegate.shared?.showAlertMessageWithActionOK(self, "错误提示", error.localizedDescription)
            }
        })
        self.present(alert, animated: true, completion: nil)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "foodOderingSegue" {
            
            let destView = segue.destination as! FoodOrderingViewController
            destView.delegate = self
            destView.currentOrderBill = self.currentOrderBill
        }
        if segue.identifier == "addOtherItemSegue" {
            
            let destView = segue.destination as! FoodOrderingAddOtherItemsViewController
            destView.delegate = self
            destView.currentOrderBill = self.currentOrderBill
        }
        if segue.identifier == "editOrderSegue" {
            
            let destView = segue.destination as! FoodOrderingNewOrderDialog
            destView.delegate = self
            destView.currentOrderBill = self.currentOrderBill
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        
        if identifier == "foodOderingSegue" {
            if self.currentOrderBill!.finished || self.currentOrderBill!.cancelled {
                return false
            }
        }
        else if identifier == "addOtherItemSegue" {
            if self.currentOrderBill!.finished || self.currentOrderBill!.cancelled {
                return false
            }
        }
        return true
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if summaryDetailSegment.selectedSegmentIndex == 0 {
            
            return (orderItemsSum?.count ?? 0) + 3
        } else {
            
            return (orderItems?.count ?? 0) + 3
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                
        var orderItems: [OrderItemTable.OrderItem]?

        if summaryDetailSegment.selectedSegmentIndex == 0 {
            
            orderItems = self.orderItemsSum
        } else {
            
            orderItems = self.orderItems
        }
        
        
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "itemDetailOrderInfoCell") as! orderDetailOrderInfoTableViewCell
            
            cell.tableNameLabel.text = (self.currentOrderBill?.name ?? "") == "" ? "无桌名" : self.currentOrderBill?.name
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            cell.createTimeLabel.text = dateFormatter.string(from: Date(timeIntervalSince1970: self.currentOrderBill?.createStamp ?? 0))
            
            var totalMoney = 0.0
            for item in orderItems ?? [OrderItemTable.OrderItem]() {
                
                totalMoney = totalMoney + Double(item.count) * item.price
            }
            cell.totalMoneyLabel.text = "CNY￥: \(totalMoney)"
            
            
            if self.currentOrderBill!.finished || self.currentOrderBill!.cancelled {
                
                cell.editButton.setTitleColor(UIColor.systemGray, for: UIControl.State.disabled)
                cell.finishButton.setTitleColor(UIColor.systemGray, for: UIControl.State.disabled)
                cell.cancellButton.setTitleColor(UIColor.systemGray, for: UIControl.State.disabled)
                cell.editButton.isEnabled = false
                cell.finishButton.isEnabled = false
                cell.cancellButton.isEnabled = false
            }
            
            return cell
        }  else if indexPath.row == (orderItems?.count ?? 0) + 1 {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "itemDetailSummaryCell") as! orderDetailSummaryTableViewCell
            var totalMoney = 0.0
            for item in orderItems ?? [OrderItemTable.OrderItem]() {
                
                totalMoney = totalMoney + Double(item.count) * item.price
            }
            cell.totalMoneyLabel.text = "￥：\(totalMoney)"
            
            return cell
            
        } else if indexPath.row == (orderItems?.count ?? 0) + 2 {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "itemDetailDeleteCell")!
            
            return cell
        }
        else {
        
            let indexPath = IndexPath(row: indexPath.row - 1, section: indexPath.section)
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "itemDetailCell") as! orderDetailTableViewCell
            
            if let items = orderItems {
                
                cell.foodNameLabel.text = items[indexPath.row].itemName
                cell.foodNumberLabel.text = "\(items[indexPath.row].count)"
                cell.foodMoneyLabel.text = "￥：\(Double(items[indexPath.row].count) * items[indexPath.row].price)"
            }
            
            return cell
        }
    }
    
    // MARK: FoodOrderingAddOtherItemsViewControllerDelegate
    
    func foodOrderingAddOtherItemsViewControllerConfrimed(sender: FoodOrderingAddOtherItemsViewController) {
        
        self.reloadData()
        self.tableView.reloadData()
    }
    
    // MARK: FoodOrderingNewOrderDialogDelegate
    
    func foodOrderingNewOrderDialogCancell(_ controller: FoodOrderingNewOrderDialog) {
        //
    }
    // edit current order properties
    func foodOrderingNewOrderDialogConfirm(_ controller: FoodOrderingNewOrderDialog) {
        
        do {
            try AppDelegate.shared?.dbWrapper?.update(controller.currentOrderBill!, from: OrderBillTable.self)
            
            self.currentOrderBill = controller.currentOrderBill
            
            AppDelegate.shared?.showAlertMessageAutoDismiss(self, "订单修改成功！", nil, dismissAfter: DispatchTime.now() + 0.8)
            self.tableView.reloadData()
        } catch {
            
            AppDelegate.shared?.showAlertMessageWithActionOK(self, "错误提示", error.localizedDescription)
            debugPrint(error.localizedDescription)
        }
    }
}

class orderDetailTableViewCell: UITableViewCell {
    
    @IBOutlet weak var foodNameLabel: UILabel!
    
    @IBOutlet weak var foodNumberLabel: UILabel!
    
    @IBOutlet weak var foodMoneyLabel: UILabel!
}

class orderDetailSummaryTableViewCell: UITableViewCell {
    
    @IBOutlet weak var totalMoneyLabel: UILabel!
}

class orderDetailDeleteTableViewCell: UITableViewCell {
    
}

class orderDetailEditTableViewCell: UITableViewCell {
    
}

class orderDetailOrderInfoTableViewCell: UITableViewCell {
    
    @IBOutlet weak var tableNameLabel: UILabel!
    
    @IBOutlet weak var totalMoneyLabel: UILabel!
    
    @IBOutlet weak var createTimeLabel: UILabel!
    
    @IBOutlet weak var editButton: UIButton!
    
    @IBOutlet weak var finishButton: UIButton!
    
    @IBOutlet weak var cancellButton: UIButton!
    
}
