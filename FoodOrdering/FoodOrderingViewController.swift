//
//  FoodOrderingViewController.swift
//  FoodOrdering
//
//  Created by fOrest on 2020/4/18.
//  Copyright © 2020 fOrest. All rights reserved.
//

import Foundation
import UIKit

protocol FoodOrderingViewControllerDelegate {
    
    func foodOrderingViewControllerOrderItemsSaved(_ sender: FoodOrderingViewController)
}

class FoodOrderingViewController: UICollectionViewController, FoodOrderingInputDialogDelegate {
    
    var dataSaved: Bool = false
    
    var allCategories: [[String: Any?]]?
    
    var allFoods: [[[String: Any?]]?]?
    
    var orderedFoods: [OrderItemTable.OrderItem]?
    
    var newOrderingFoods: [OrderItemTable.OrderItem]?
    
    var currentOrderBill: OrderBillTable.OrderBill?
    
    var lastTouchedIndexPath: IndexPath?
    
    var delegate: FoodOrderingViewControllerDelegate?
    
    func reloadData() {
        
        do {
            
            orderedFoods = try AppDelegate.shared?.dbWrapper?.readOrderItems(by: self.currentOrderBill?.id ?? -1)
            
            allCategories = try AppDelegate.shared?.dbWrapper?.read(from: MenuCategoryTable.self, where: nil, orderBy: nil)
            
            if let categories = allCategories {
                  
                allFoods = [[[String: Any?]]?]()
                
                for category in categories {
                    
                    let categoryId = category[MenuCategoryTable.MenuCategory.CodingKeys.id.rawValue]!!
                    
                    if let foods = try AppDelegate.shared?.dbWrapper?.read(from: MenuItemTable.self, where: [MenuItemTable.MenuItem.CodingKeys.category.rawValue: categoryId], orderBy: [(MenuItemTable.MenuItem.CodingKeys.id.rawValue, SqlQueryOrder.ASC)]) {
                        
                        allFoods?.append(foods)
                    } else {
                        
                        allFoods?.append(nil)
                    }
                }
            }
            else {
                
                self.allFoods = nil
            }
        }catch {
            
            AppDelegate.shared?.showAlertMessageWithActionOK(self, error.localizedDescription, nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Order Foods"
        
        self.reloadData()
        self.collectionView.allowsMultipleSelection = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if !dataSaved && (newOrderingFoods?.count ?? 0) != 0 {
            
            AppDelegate.shared?.showAlertMessageWithActionOK(self.delegate as? UIViewController, "添加的菜品没有保存！", nil)
        }
    }
    
    @IBAction func confirmOrderButtonTouched(_ sender: Any) {
        
        do {
            for item in self.newOrderingFoods ?? [OrderItemTable.OrderItem]() {
                
                if var values = item.values {
                    
                    values.removeValue(forKey: OrderItemTable.OrderItem.CodingKeys.serial.rawValue)
                    
                    try AppDelegate.shared?.dbWrapper?.insert(into: OrderItemTable.self, with: values)
                }
                self.dataSaved = true
            }
        }
        catch {

            //AppDelegate.shared?.showAlertMessageWithActionOK(self, "错误提示", error.localizedDescription)
            debugPrint(error)
        }
        
        self.navigationController?.popViewController(animated: true)
        delegate?.foodOrderingViewControllerOrderItemsSaved(self)
    }
            
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        collectionView.deselectItem(at: indexPath, animated: false)
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionView.elementKindSectionHeader {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "orderHeaderCell", for: indexPath) as! FoodOrderingHeaderView
            view.headerLabel.text = allCategories?[indexPath.section][MenuCategoryTable.MenuCategory.CodingKeys.name.rawValue] as? String
            
            return view
        }
        return UICollectionReusableView()
    }
        
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "foodItemCell", for: indexPath) as! FoodOrderingCell
        
        if let foods = allFoods?[indexPath.section] {
            
            if let food = try? JSONDecoder().decode(MenuItemTable.MenuItem.self, from: try! JSONSerialization.data(withJSONObject: foods[indexPath.item], options: [])) {
                
                ///
                var orderedNumber: Int64 = 0
                for item in orderedFoods ?? [OrderItemTable.OrderItem]() where item.itemId == food.id {
                    
                    orderedNumber = orderedNumber + item.count
                }
                
                var orderingNumber: Int64 = 0
                for item in newOrderingFoods ?? [OrderItemTable.OrderItem]() where item.itemId == food.id {
                    
                    orderingNumber = item.count
                }
                ///
                cell.foodItem = food
                cell.orderedNumber = orderedNumber
                cell.orderingNumber = orderingNumber
                ///
                
                cell.orderedNumberBackgroundImageView.isHidden = true
                cell.orderedNumberTextField.isHidden = true
                cell.orderingNumberBackgroundImageView.isHidden = true
                cell.orderingNumberTextField.isHidden = true
                
                if orderedNumber != 0 || orderingNumber != 0 {
                    
                    if orderingNumber != 0 {
                        cell.orderingNumberBackgroundImageView.isHidden = false
                        cell.orderingNumberTextField.isHidden = false
                        cell.orderingNumberTextField.text = "\(orderingNumber)"
                        
                        if orderedNumber != 0 {
                            
                            cell.orderedNumberBackgroundImageView.isHidden = false
                            cell.orderedNumberTextField.isHidden = false
                            cell.orderedNumberTextField.text = "\(orderedNumber)"
                        }
                    } else {
                        
                        cell.orderingNumberBackgroundImageView.isHidden = false
                        cell.orderingNumberTextField.isHidden = false
                        cell.orderingNumberTextField.text = "\(orderedNumber)"
                    }
                    cell.backgroudImageView.isHighlighted = true
                } else {
                    
                    cell.backgroudImageView.isHighlighted = false
                }
                
                cell.foodNameTextFieldNormal.text = food.name
            }
        }
        return cell
    }
    
    override func numberOfSections(in tableView: UICollectionView) -> Int {
        
        return allCategories?.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allFoods?[section]?.count ?? 0
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "foodOrderingDialogSegue" {
            
            let destView = segue.destination as! FoodOrderingInputDialog
            destView.delegate = self
            
            if let cell = (sender as? FoodOrderingCell) {
                destView.foodItem = cell.foodItem
                destView.orderedNumber = cell.orderedNumber
                destView.newOrderingNumber = cell.orderingNumber
            }
        }
    }
    
    // MARK: FoodOrderingInputDialogDelegate
    
    func foodOrderingInputDialogConfirmed(_ sender: FoodOrderingInputDialog) {
        
        var foodItemOrdered = false
        let newOrderingNumber = sender.newOrderingNumber ?? 0
        let foodItem = sender.foodItem
        
        for index in 0..<(newOrderingFoods?.count ?? 0) {
            
            if newOrderingFoods![index].itemId == sender.foodItem?.id {
                // ensure not zero
                newOrderingFoods![index].count = newOrderingNumber
                
                foodItemOrdered = true
                
                if newOrderingFoods![index].count == 0 {
                    
                    newOrderingFoods!.remove(at: index)
                }
            }
        }
        
        if newOrderingNumber != 0 && !foodItemOrdered {
            
            newOrderingFoods = (newOrderingFoods == nil) ? [OrderItemTable.OrderItem]() : newOrderingFoods
            
            newOrderingFoods!.append(OrderItemTable.OrderItem(serial: -1, orderId: self.currentOrderBill!.id, itemId: foodItem!.id, itemName: foodItem!.name, remarks: nil, count: newOrderingNumber, price: foodItem!.price, timestamp: Date().timeIntervalSince1970) )
        }
        self.collectionView.reloadData()
    }
}

extension DbWrapper {
    
    func readOrderItems(by orderId: Int64) throws -> [OrderItemTable.OrderItem]? {
        
        let values = try read(from: OrderItemTable.self, where: [OrderItemTable.OrderItem.CodingKeys.orderId.rawValue: orderId], orderBy: [( OrderItemTable.OrderItem.CodingKeys.timestamp.rawValue, SqlQueryOrder.ASC)])
        
        var orderItems = [OrderItemTable.OrderItem]()
        for item in values ?? [[String: Any?]]() {
            
            if let orderItem = try? JSONDecoder().decode(OrderItemTable.OrderItem.self, from: try! JSONSerialization.data(withJSONObject: item, options: [])) {
                
                orderItems.append(orderItem)
            }
        }
        if orderItems.count == 0 {
            return nil
        } else {
            return orderItems
        }
    }
}
