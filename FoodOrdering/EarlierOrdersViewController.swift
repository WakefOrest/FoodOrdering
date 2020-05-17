//
//  SecondViewController.swift
//  FoodOrdering
//
//  Created by fOrest on 2020/1/15.
//  Copyright © 2020 fOrest. All rights reserved.
//

import UIKit

class EarlierOrdersViewController: UITableViewController, UINavigationControllerDelegate, DatePickViewControllerDelegate {

    @IBOutlet weak var ordersSegmentControll: UISegmentedControl!
    
    var allOrders: [OrderBillTable.OrderBill]?
            
    var allOrderItems: [[OrderItemTable.OrderItem]?]?
    
    var allOrderItemsSum: [[OrderItemTable.OrderItem]?]?
    
    var currentDate: Date?

    func reloadData() {
        
        guard self.currentDate != nil else {
            
            self.allOrders = nil;self.allOrderItems = nil;self.allOrderItemsSum = nil
            return
        }
        
        do {
            
            if ordersSegmentControll.selectedSegmentIndex == 0 {
                
                try self.allOrders = AppDelegate.shared?.dbWrapper?.readOrderBillsByDate(date: self.currentDate!)
            } else {
                
                try self.allOrders = AppDelegate.shared?.dbWrapper?.readActiveOrderBillsByDate(date: self.currentDate!)
            }
            
            if let orders = self.allOrders {
                
                allOrderItems = [[OrderItemTable.OrderItem]?]()
                for order in orders {
                    if let items = try AppDelegate.shared?.dbWrapper?.readOrderItems(by: order.id) {
                        allOrderItems?.append(items)
                    } else {
                        allOrderItems?.append(nil)
                    }
                }
                
                if allOrderItems?.count == 0 {
                    allOrderItems = nil
                }
            }
            
            if let orderItems = allOrderItems {
                
                allOrderItemsSum = [[OrderItemTable.OrderItem]?]()
                for items in orderItems {
                    
                    if items == nil {
                        
                        allOrderItemsSum!.append(items)
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
                        allOrderItemsSum!.append(itemsSum)
                    }
                }
                if allOrderItemsSum?.count == 0 {
                    
                    allOrderItemsSum = nil
                }
            }
        }catch {
            AppDelegate.shared?.showAlertMessageWithActionOK(self, "错误提示", error.localizedDescription)
        }
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        navigationItem.title = "所有订单"
        
        ordersSegmentControll.selectedSegmentIndex = 0
        ordersSegmentControll.setTitleTextAttributes([NSAttributedString.Key.font : UIFont.systemFont(ofSize: 36)], for: .normal)
        ordersSegmentControll.frame = CGRect(x: ordersSegmentControll.frame.minX, y: ordersSegmentControll.frame.minY - 5, width: ordersSegmentControll.frame.width, height: ordersSegmentControll.frame.height + 5)
                
        self.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         
         if segue.identifier == "orderDetailSegue2" {
             
            let destView = segue.destination as! OrderDetailViewController
            if let cell = sender as? EarlierOrdersTabelViewCell {
                
                destView.currentOrderBill = cell.currentOrderBill
            }
         } else if segue.identifier == "datePickSegue" {
             
            let destView = segue.destination as! DatePickViewController
            destView.delegate = self
         }
     }
    
    @IBAction func orderSegmentValueChanged(_ sender: Any) {
        
        self.reloadData()
        self.tableView.reloadData()
        
        if self.tableView.numberOfRows(inSection: 0) > 0 {
            self.tableView.scrollToRow(at: IndexPath(row: self.tableView.numberOfRows(inSection: 0) - 1, section: 0), at: UITableView.ScrollPosition.bottom, animated: false)
        }
    }
    
    // MARK: UITableViewDataSource
        
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return allOrders?.count ?? 0
    }
        
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "earlierOrdersCell")! as! EarlierOrdersTabelViewCell
        
        cell.isFinished = allOrders?[indexPath.row].finished ?? false
        cell.isCancelled = allOrders?[indexPath.row].cancelled ?? false
        cell.isTakeAway = allOrders?[indexPath.row].takeAway ?? false
        
        cell.tableName = allOrders?[indexPath.row].name ?? "无桌名"
        cell.createTime = allOrders?[indexPath.row].createStamp
        
        var totalMoney: Double = 0.0
        if let items = allOrderItems![indexPath.row] {
            for item in items {
                
                totalMoney = totalMoney + Double(item.count) * item.price
            }
        }
        cell.totalMoney = totalMoney
        
        cell.currentOrderBill = allOrders?[indexPath.row]
        
        return cell
    }
    
    // MARK: DatePickViewControllerDelegate
    
    func datePickViewControllerDateDidPick(sender: DatePickViewController) {
        
        self.currentDate = sender.date
                
        self.reloadData()
        self.tableView.reloadData()
    }
    
    // MARK: UINavigationControllerDelegate
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        
        if viewController == self {
            
            self.reloadData()
            self.tableView.reloadData()
        }
    }
}

class EarlierOrdersTabelViewCell: UITableViewCell {
    
    @IBOutlet weak var tableNameLabel: UILabel!
    
    @IBOutlet weak var totalMoneyLabel: UILabel!
    
    @IBOutlet weak var createTimeLabel: UILabel!
    
    @IBOutlet weak var takeAwayLabel: UILabel!
    
    @IBOutlet weak var orderStateLabel: UILabel!
    
    var currentOrderBill: OrderBillTable.OrderBill?
    
    var tableName: String? {
        get {
            return self.tableNameLabel.text
        }
        set (value) {
            self.tableNameLabel.text = value
        }
    }
    
    var totalMoney: Double? {
        
        get {
            return Double(self.totalMoneyLabel.text ?? "")
        }
        set (value) {
            self.totalMoneyLabel.text = "￥: \(value ?? 0.0)"
        }
    }
    
    var createTime: TimeInterval? {
        
        get {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return dateFormatter.date(from: createTimeLabel.text ?? "")?.timeIntervalSince1970
        }
        set(value) {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            createTimeLabel.text = dateFormatter.string(from: Date(timeIntervalSince1970: value ?? 0))
        }
    }
    
    var isTakeAway: Bool? {
        get { if let text = self.takeAwayLabel.text {
            if text != "" {
                return true
            } else { return false }
        } else {return false }
        }
        set(value) {
            self.takeAwayLabel.text = (value ?? false ) ? "打包" : ""
        }
    }
    
    var isFinished: Bool? {
        
        get { if let text = self.orderStateLabel.text {
            if text == "已完成" {
                return true
            } else { return false }
        } else {return false }
        }
        set(value) {
            self.orderStateLabel.textColor = UIColor.green
            self.orderStateLabel.text = (value ?? false ) ? "已完成" : ""
        }
    }
    
    var isCancelled: Bool? {
        
        get { if let text = self.orderStateLabel.text {
            if text == "已取消" {
                return true
            } else { return false }
        } else {return false }
        }
        set(value) {
            self.orderStateLabel.textColor = UIColor.red
            self.orderStateLabel.text = (value ?? false ) ? "已取消" : ""
        }
    }
}

protocol DatePickViewControllerDelegate {
    
    func datePickViewControllerDateDidPick(sender: DatePickViewController)
}

class DatePickViewController: UIViewController {
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    var date: Date {
        
        get { return Calendar.current.startOfDay(for: self.datePicker.date) }
    }
    
    var delegate: DatePickViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func confirmButtonDidTouch(_ sender: Any) {
        
        self.dismiss(animated: true) {
            self.delegate?.datePickViewControllerDateDidPick(sender: self)
        }
    }
}


extension DbWrapper {
    
    func readOrderBillsByDate(date: Date) throws -> [OrderBillTable.OrderBill]? {
        
        let timeStamp = date.timeIntervalSince1970 + (60 * 60 * 24)
        let conditions = "\(OrderBillTable.OrderBill.CodingKeys.createStamp.rawValue) > \(date.timeIntervalSince1970) AND \(OrderBillTable.OrderBill.CodingKeys.createStamp.rawValue) <= \(timeStamp)"
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
    
    func readActiveOrderBillsByDate(date: Date) throws -> [OrderBillTable.OrderBill]? {
        
        let timeStamp = date.timeIntervalSince1970 + (60 * 60 * 24)
        let conditions = "\(OrderBillTable.OrderBill.CodingKeys.createStamp.rawValue) > \(date.timeIntervalSince1970) AND \(OrderBillTable.OrderBill.CodingKeys.createStamp.rawValue) <= \(timeStamp) AND \(OrderBillTable.OrderBill.CodingKeys.finished.rawValue) = 0 AND \(OrderBillTable.OrderBill.CodingKeys.cancelled.rawValue) = 0"
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
}

