//
//  FirstViewController.swift
//  FoodOrdering
//
//  Created by fOrest on 2020/1/15.
//  Copyright © 2020 fOrest. All rights reserved.```````````````````````````````````````````````````````````````
//

import UIKit

class TodaysOrdersViewController: UITableViewController, FoodOrderingNewOrderDialogDelegate, FoodOrderingViewControllerDelegate, UINavigationControllerDelegate {
        
    @IBOutlet weak var todaysOrdersSegment: UISegmentedControl!
    
    var todaysOrders: [OrderBillTable.OrderBill]?
            
    var todaysOrderItems: [[OrderItemTable.OrderItem]?]?
    
    var todaysOrderItemsSum: [[OrderItemTable.OrderItem]?]?
    
    var currentSelectedOrderBill: OrderBillTable.OrderBill?
    
    var currentSelectedIndexPath: IndexPath?
    
    func reloadData() {
        
        do {
            if todaysOrdersSegment.selectedSegmentIndex == 0 {
                
            try self.todaysOrders = AppDelegate.shared?.dbWrapper?.readTodaysActiveOrderBills()
            } else {
                
                try self.todaysOrders = AppDelegate.shared?.dbWrapper?.readTodaysOrderBills()
            }
            
            if let orders = self.todaysOrders {
                
                todaysOrderItems = [[OrderItemTable.OrderItem]?]()
                for order in orders {
                    if let items = try AppDelegate.shared?.dbWrapper?.readOrderItems(by: order.id) {
                        todaysOrderItems?.append(items)
                    } else {
                        todaysOrderItems?.append(nil)
                    }
                }
                
                if todaysOrderItems?.count == 0 {
                    todaysOrderItems = nil
                }
            }
            
            if let orderItems = todaysOrderItems {
                
                todaysOrderItemsSum = [[OrderItemTable.OrderItem]?]()
                for items in orderItems {
                    
                    if items == nil {
                        
                        todaysOrderItemsSum!.append(items)
                    } else {
                        var itemsSum = [OrderItemTable.OrderItem]()
                        for item in items! {
                            
                            if itemsSum.contains(where: { (orderItem) -> Bool in
                                if orderItem.itemId != nil && orderItem.itemId == item.itemId { return true } else { return false }
                            }) {
                                for index in 0..<itemsSum.count where itemsSum[index].itemId == item.itemId {
                                    
                                    itemsSum[index].count = itemsSum[index].count + item.count
                                }
                            } else {
                                itemsSum.append(item)
                            }
                        }
                        todaysOrderItemsSum!.append(itemsSum)
                    }
                }
                if todaysOrderItemsSum?.count == 0 {
                    
                    todaysOrderItemsSum = nil
                }
            }
        }catch {
            
            AppDelegate.shared?.showAlertMessageWithActionOK(self, error.localizedDescription, nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        navigationItem.title = "今日订单"
//        tableView.rowHeight = UITableView.automaticDimension
//        tableView.estimatedRowHeight = UITableView.automaticDimension
        self.navigationController?.delegate = self
        
        todaysOrdersSegment.selectedSegmentIndex = 0
        todaysOrdersSegment.setTitleTextAttributes([NSAttributedString.Key.font : UIFont.systemFont(ofSize: 36)], for: .normal)
        todaysOrdersSegment.frame = CGRect(x: todaysOrdersSegment.frame.minX, y: todaysOrdersSegment.frame.minY - 5, width: todaysOrdersSegment.frame.width, height: todaysOrdersSegment.frame.height + 5)
        self.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "newOrderSegue" {
            
            let destView = segue.destination as! FoodOrderingNewOrderDialog
            destView.delegate = self
        }
        if segue.identifier == "foodOrderingSegue" {
            
            let destView = segue.destination as! FoodOrderingViewController
            destView.delegate = self
            destView.currentOrderBill = sender as? OrderBillTable.OrderBill
        }
        if segue.identifier == "orderDetailSegue" {
            
            let destView = segue.destination as! OrderDetailViewController
            destView.currentOrderBill = self.currentSelectedOrderBill
        }
    }
   
    @IBAction func todaysOrdersSegmentValueChanged(_ sender: Any) {
        
        self.reloadData()
        self.tableView.reloadData()
        self.tableView.scrollToRow(at: IndexPath(row: self.tableView.numberOfRows(inSection: 0) - 1, section: 0), at: UITableView.ScrollPosition.bottom, animated: false)
    }
    
    
    // MARK: NewOrderViewControllerDelegate
        
    func foodOrderingNewOrderDialogCancell(_ controller: FoodOrderingNewOrderDialog) {
        // do nothing
    }
    
    func foodOrderingNewOrderDialogConfirm(_ controller: FoodOrderingNewOrderDialog) {
        
        let orderBill = controller.currentOrderBill!
        
        do {
            if var values = orderBill.values {
                
                values.removeValue(forKey: OrderBillTable.OrderBill.CodingKeys.id.rawValue)
                
                try AppDelegate.shared?.dbWrapper?.insert(into: OrderBillTable.self, with: values)
            }
            
            // to get auto-increased order id
            if let newOrderBill = try AppDelegate.shared?.dbWrapper?.readOrderBillByCreateTime(createTime: orderBill.createStamp) {

                performSegue(withIdentifier: "foodOrderingSegue", sender: newOrderBill)

            } else {
                
                self.reloadData()
                self.tableView.reloadData()
                
                self.tableView.scrollToRow(at: IndexPath(row: self.tableView.numberOfRows(inSection: 0) - 1, section: 0), at: UITableView.ScrollPosition.bottom, animated: false)
            }
        } catch {
            
            AppDelegate.shared?.showAlertMessageWithActionOK(self, "错误提示", error.localizedDescription)
        }
    }
    
    // MARK: FoodOrderingViewControllerDelegate
    func foodOrderingViewControllerOrderItemsSaved(_ sender: FoodOrderingViewController) {
        
//            self.reloadData()
//            self.tableView.reloadData()
    }
    
    // MARK: UINavigationControllerDelegate
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        
        if viewController == self {
            
            let oldOrderCount = self.todaysOrders?.count ?? 0
            self.reloadData()
            
            if (self.todaysOrders?.count ?? 0) > oldOrderCount {
                
                self.tableView.reloadData()
                
                self.tableView.scrollToRow(at: IndexPath(row: self.tableView.numberOfRows(inSection: 0) - 1, section: 0), at: UITableView.ScrollPosition.bottom, animated: false)
            } else if (self.todaysOrders?.count ?? 0) < oldOrderCount {
                
                self.tableView.reloadData()
            } else {
                
                UIView.performWithoutAnimation {
                    self.tableView.reloadRows(at: self.tableView.indexPathsForVisibleRows ?? [], with: UITableView.RowAnimation.none)
                }
                //self.tableView.reloadRows(at: [(self.currentSelectedIndexPath ?? IndexPath(row: 0, section: 0))], with: UITableView.RowAnimation.none)
            }
        }
    }
}

extension TodaysOrdersViewController {
        
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        self.currentSelectedOrderBill = todaysOrders?[indexPath.row]
        self.currentSelectedIndexPath = indexPath
        return indexPath
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.currentSelectedOrderBill = todaysOrders?[indexPath.row]
        self.currentSelectedIndexPath = indexPath
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return todaysOrders?.count ?? 0
    }
        
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "regularCell")! as! TodaysOrdersTableViewCell
        
        if todaysOrders?[indexPath.row].finished ?? false {
            
            cell.orderStateLabel.text = "已完成"
            cell.orderStateLabel.textColor = UIColor.systemGreen
        } else if todaysOrders?[indexPath.row].cancelled ?? false {
            
            cell.orderStateLabel.text = "已取消"
            cell.orderStateLabel.textColor = UIColor.systemRed
        } else {
            cell.orderStateLabel.text = ""
            cell.orderStateLabel.textColor = UIColor.black
        }
        
        cell.isTakeAway = todaysOrders?[indexPath.row].takeAway ?? false
        cell.tableNameTextField.text = todaysOrders?[indexPath.row].name ?? ""
        cell.createTime = todaysOrders?[indexPath.row].createStamp ?? 0.0
        var totalMoney: Double = 0.0
        if let items = todaysOrderItems![indexPath.row] {
            for item in items {
                
                totalMoney = totalMoney + Double(item.count) * item.price
            }
        }
        cell.totalMoneyTextField.text = "￥：\(totalMoney)"
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let tableViewCell = cell as? TodaysOrdersTableViewCell else { return }

        tableViewCell.setCollectionViewDataSourceDelegate(self, at: indexPath)
    }
    
}

extension TodaysOrdersViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return todaysOrderItemsSum?[collectionView.tag]?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "foodItemCell", for: indexPath) as! OrdersItemsCell
        
        cell.itemNameTextField.text = ""
        cell.itemNumberTextField.text = ""
        
        if let items = todaysOrderItemsSum?[collectionView.tag] {
            let item = items[indexPath.item]
            
            cell.itemNameTextField.text = item.itemName
            cell.itemNumberTextField.text = "\(item.count)"
        }
        return cell
    }
}

extension DbWrapper {
        
    func readTodaysOrderBills() throws -> [OrderBillTable.OrderBill]? {
        
        let timeStamp = Date().timeIntervalSince1970 - (60 * 60 * 24)
        let conditions = "\(OrderBillTable.OrderBill.CodingKeys.createStamp.rawValue) > \(timeStamp)"
        let values = try read(from: OrderBillTable.self, by: conditions, orderBy: [ (OrderBillTable.OrderBill.CodingKeys.finished.rawValue, SqlQueryOrder.DESC), (OrderBillTable.OrderBill.CodingKeys.cancelled.rawValue, SqlQueryOrder.DESC), (OrderBillTable.OrderBill.CodingKeys.id.rawValue, SqlQueryOrder.ASC)])
        
        var orderBills = [OrderBillTable.OrderBill]()
        for item in values ?? [[String: Any?]]() {
            
            if let orderBill = try? JSONDecoder().decode(OrderBillTable.OrderBill.self, from: try! JSONSerialization.data(withJSONObject: item, options: [])) {
                
                orderBills.append(orderBill)
            }
        }
        if orderBills.count == 0 {
            return nil
        } else {
            return orderBills
        }
    }
    
    func readTodaysActiveOrderBills() throws -> [OrderBillTable.OrderBill]? {
        
        let timeStamp = Date().timeIntervalSince1970 - (60 * 60 * 24)
        let conditions = "\(OrderBillTable.OrderBill.CodingKeys.createStamp.rawValue) > \(timeStamp) AND \(OrderBillTable.OrderBill.CodingKeys.finished.rawValue) = 0 AND \(OrderBillTable.OrderBill.CodingKeys.cancelled.rawValue) = 0"
        let values = try read(from: OrderBillTable.self, by: conditions, orderBy: [(OrderBillTable.OrderBill.CodingKeys.id.rawValue, SqlQueryOrder.ASC)])
        
        var orderBills = [OrderBillTable.OrderBill]()
        for item in values ?? [[String: Any?]]() {
            
            if let orderBill = try? JSONDecoder().decode(OrderBillTable.OrderBill.self, from: try! JSONSerialization.data(withJSONObject: item, options: [])) {
                
                orderBills.append(orderBill)
            }
        }
        if orderBills.count == 0 {
            return nil
        } else {
            return orderBills
        }
    }
    
    func readOrderBillByCreateTime(createTime: TimeInterval )throws -> OrderBillTable.OrderBill? {
        
        let values = try read(from: OrderBillTable.self, where: [OrderBillTable.OrderBill.CodingKeys.createStamp.rawValue: createTime], orderBy: nil)
        
        for item in values ?? [[String: Any?]]() {
            
            if let orderBill = try? JSONDecoder().decode(OrderBillTable.OrderBill.self, from: try! JSONSerialization.data(withJSONObject: item, options: [])) {
                
                return orderBill
            }
        }
        return nil
    }
    
    func readOrderBillByOrderId(orderId: Int64)throws -> OrderBillTable.OrderBill? {
        
        let values = try read(from: OrderBillTable.self, where: [OrderBillTable.OrderBill.CodingKeys.id.rawValue: orderId], orderBy: nil)
        
        for item in values ?? [[String: Any?]]() {
            
            if let orderBill = try? JSONDecoder().decode(OrderBillTable.OrderBill.self, from: try! JSONSerialization.data(withJSONObject: item, options: [])) {
                
                return orderBill
            }
        }
        return nil
    }
}
