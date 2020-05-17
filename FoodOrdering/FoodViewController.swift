//
//  FoodViewController.swift
//  FoodOrdering
//
//  Created by fOrest on 2020/4/28.
//  Copyright © 2020 fOrest. All rights reserved.
//

import UIKit

class FoodViewController: UITableViewController, NewFoodViewControllerDelegate, FoodDetailViewControllerDelegate {
    
    var allCategories: [[String: Any?]]?
    
    var allFoods: [[[String: Any?]]?]?
    
    func reloadData() {
        do {
            allCategories = try AppDelegate.shared?.dbWrapper?.read(from: MenuCategoryTable.self, where: nil, orderBy: [(MenuCategoryTable.MenuCategory.CodingKeys.id.rawValue, SqlQueryOrder.ASC)])
            
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
    //
        
        reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "ShowNewFood" {
            
            let destView = segue.destination as! NewFoodViewController
            destView.delegate = self
        }
        if segue.identifier == "foodDetailSegue" {

            let destView = segue.destination as! FoodDetailViewController
            destView.delegate = self
            
            if let cell = (sender as? FoodTableViewCell) {
                
                destView.currentFoodItem = cell.currentFoodItem
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return allCategories?[section][MenuCategoryTable.MenuCategory.CodingKeys.name.rawValue] as? String
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "foodTableViewCell") as! FoodTableViewCell
        
        if let foods = allFoods?[indexPath.section] {
            
            if let food = try? JSONDecoder().decode(MenuItemTable.MenuItem.self, from: try! JSONSerialization.data(withJSONObject: foods[indexPath.row], options: [])) {
                
                cell.foodTitleLabel.text = "\(food.id)   " + food.name
                cell.currentFoodItem = food
            }
        }
        
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return allCategories?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return allFoods?[section]?.count ?? 0
    }
    
    
    // MARK: NewFoodViewControllerDelegate
    
    func newFoodAddSucceeded(_ sender: NewFoodViewController) {
        
        AppDelegate.shared?.showAlertMessageAutoDismiss(self, "菜品添加成功！", nil, dismissAfter: DispatchTime.now() + 0.8)
        
        reloadData()
        tableView.reloadData()
    }
    
    // MARK: foodDetailViewControllerDelegate
    
    func foodDetailViewControllerfoodChanged(sender: FoodDetailViewController) {
        
        AppDelegate.shared?.showAlertMessageAutoDismiss(self, "菜品修改成功！", nil, dismissAfter: DispatchTime.now() + 0.8)
        
        reloadData()
        tableView.reloadData()
        
    }
    
    func foodDetailViewControllerfoodDeleted(sender: FoodDetailViewController) {
        
        AppDelegate.shared?.showAlertMessageAutoDismiss(self, "菜品删除成功！", nil, dismissAfter: DispatchTime.now() + 0.8)
        
        reloadData()
        tableView.reloadData()
    }
    
}

class FoodTableViewCell: UITableViewCell {
    
    @IBOutlet weak var foodTitleLabel: UILabel!
    
    var currentFoodItem: MenuItemTable.MenuItem?
}

///
protocol NewFoodViewControllerDelegate {
    
    func newFoodAddSucceeded(_ sender: NewFoodViewController)
}

class NewFoodViewController: UIViewController, UIPickerViewAccessibilityDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var foodNameTextField: UITextField!
    
    @IBOutlet weak var categoryPicker: UIPickerView!
    
    @IBOutlet weak var priceTextField: UITextField!
    
    @IBOutlet weak var priceStepper: UIStepper!
    
    var delegate: NewFoodViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        categoryPicker.delegate = self
        categoryPicker.dataSource = self
    }
    
    @IBAction func priceStepperValueChanged(_ sender: Any) {
        
        self.priceTextField.text = String(self.priceStepper.value)
    }
    
    @IBAction func confirmButtonDidTouch(_ sender: Any) {
        
        if (delegate as? FoodViewController)?
            .allCategories == nil {
            return
        }
        let foodCategory = (delegate as? FoodViewController)?
            .allCategories?[categoryPicker.selectedRow(inComponent: 0)][MenuCategoryTable.MenuCategory.CodingKeys.id.rawValue] as! Int64
            
        let foodPrice = priceStepper.value
        
        if let foodName = foodNameTextField.text {
            
            guard foodName != ""  else {
                
                AppDelegate.shared?.showAlertMessageWithActionOK(self, "菜品名称不能为空！", nil)
                return
            }
            
            guard foodPrice > 0  else {
                
                AppDelegate.shared?.showAlertMessageWithActionOK(self, "菜品价格不能为0！", nil)
                return
            }
            
            do {
                
                let foodItem = MenuItemTable.MenuItem(id: 0, name: foodName, category: foodCategory, price: foodPrice, enabled: true)
                
                if var values = foodItem.values {
                    
                    values.removeValue(forKey: MenuItemTable.MenuItem.CodingKeys.id.rawValue)
                    
                    try AppDelegate.shared?.dbWrapper?.insert(into: MenuItemTable.self, with: values)
                }
            }catch {
                
                debugPrint(error)
                //AppDelegate.shared?.showAlertMessageWithActionOK(self, error.localizedDescription, nil)
            }
            
            self.dismiss(animated: false) {
                
                self.delegate?.newFoodAddSucceeded(self)
            }
        }
        
    }
    
    
    // MARK: UIPickerViewAccessibilityDelegate
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        
        return 80
    }

    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        260
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        var pickerLabel = view as? UILabel
        
        if (pickerLabel == nil) {
            
            pickerLabel = UILabel()
            pickerLabel?.font = UIFont.systemFont(ofSize: 40)
            pickerLabel?.textAlignment = .center
        }
        pickerLabel?.text = (delegate as? FoodViewController)?.allCategories?[row][MenuCategoryTable.MenuCategory.CodingKeys.name.rawValue] as? String

        return pickerLabel!
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return (delegate as? FoodViewController)?.allCategories?[row][MenuCategoryTable.MenuCategory.CodingKeys.name.rawValue] as? String
    }
    
    // MARK: UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        return (delegate as? FoodViewController)?.allCategories?.count ?? 0
    }
}

protocol FoodDetailViewControllerDelegate {
    
    func foodDetailViewControllerfoodDeleted(sender: FoodDetailViewController)
    func foodDetailViewControllerfoodChanged(sender: FoodDetailViewController)
}

class FoodDetailViewController: UIViewController, UIPickerViewAccessibilityDelegate, UIPickerViewDataSource  {
    
    @IBOutlet weak var foodIdTextField: UITextField!
    
    @IBOutlet weak var categoryPicker: UIPickerView!
    
    @IBOutlet weak var foodNameTextField: UITextField!
    
    @IBOutlet weak var foodPriceTextField: UILabel!
    
    @IBOutlet weak var foodPriceStepper: UIStepper!
        
    var currentFoodItem: MenuItemTable.MenuItem?
    
    var delegate: FoodDetailViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        categoryPicker.delegate = self
        categoryPicker.dataSource = self
        
        if let categories = (self.delegate as? FoodViewController)?.allCategories {
                    
            for index in 0..<categories.count {
                
                if (categories[index][MenuCategoryTable.MenuCategory.CodingKeys.id.rawValue] as? Int64) == (currentFoodItem?.category ?? 0) {
                    
                    categoryPicker.selectRow(index, inComponent: 0, animated: false)
                }
            }
        }
        
        self.foodIdTextField.text = "\(self.currentFoodItem?.id ?? 0)"
        self.foodNameTextField.text = "\(self.currentFoodItem?.name ?? "")"
        self.foodPriceTextField.text = "\(self.currentFoodItem?.price ?? 0.0)"
        self.foodPriceStepper.value = self.currentFoodItem?.price ?? 0.0
    }
        
    @IBAction func deleteButtonDidTouched(_ sender: Any) {
        
        let alert = UIAlertController(title: "提示", message: "确定要删除菜品吗？", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "取消", style: UIAlertAction.Style.default, handler: nil))
        alert.addAction(UIAlertAction(title: "删除", style: UIAlertAction.Style.destructive){ (action) in
            
            do {
                try AppDelegate.shared?.dbWrapper?.delete(from: MenuItemTable.self, where: [MenuItemTable.MenuItem.CodingKeys.id.rawValue: self.currentFoodItem?.id ?? -1])
                
                self.dismiss(animated: true) {
                    
                    self.delegate?.foodDetailViewControllerfoodDeleted(sender: self)
                }
                
            }catch {
                AppDelegate.shared?.showAlertMessageWithActionOK(self, error.localizedDescription, nil)
            }
        })
        self.present(alert, animated: false)
    }
    
    @IBAction func confrimButtonDidTouched(_ sender: Any) {
        
        let foodCategory = (delegate as? FoodViewController)?
            .allCategories?[categoryPicker.selectedRow(inComponent: 0)][MenuCategoryTable.MenuCategory.CodingKeys.id.rawValue] as! Int64
            
        let foodPrice = foodPriceStepper.value
        
        if let foodName = foodNameTextField.text {
            
            guard foodName != ""  else {
                
                AppDelegate.shared?.showAlertMessageWithActionOK(self, "菜品名称不能为空！", nil)
                return
            }
            
            guard foodPrice > 0  else {
                
                AppDelegate.shared?.showAlertMessageWithActionOK(self, "菜品价格不能为0！", nil)
                return
            }
            
            do {
                
                try AppDelegate.shared?.dbWrapper?.update(MenuItemTable.self, with: [MenuItemTable.MenuItem.CodingKeys.category.rawValue: foodCategory, MenuItemTable.MenuItem.CodingKeys.name.rawValue: foodName, MenuItemTable.MenuItem.CodingKeys.price.rawValue: foodPrice], where: [MenuItemTable.MenuItem.CodingKeys.id.rawValue: self.currentFoodItem?.id ?? -1])
                
            }catch {
                
                debugPrint(error)
                //AppDelegate.shared?.showAlertMessageWithActionOK(self, error.localizedDescription, nil)
            }
            
            self.dismiss(animated: false) {
                
                self.delegate?.foodDetailViewControllerfoodChanged(sender: self)
            }
        }
    }
    
    @IBAction func priceStepperValueChanged(_ sender: Any) {
        
        self.foodPriceTextField.text = "\(self.foodPriceStepper.value)"
    }
    
    // MARK: UIPickerViewAccessibilityDelegate
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        
        return 80
    }

    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        260
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        var pickerLabel = view as? UILabel
        
        if (pickerLabel == nil) {
            
            pickerLabel = UILabel()
            pickerLabel?.font = UIFont.systemFont(ofSize: 40)
            pickerLabel?.textAlignment = .center
        }
        pickerLabel?.text = (delegate as? FoodViewController)?.allCategories?[row][MenuCategoryTable.MenuCategory.CodingKeys.name.rawValue] as? String

        return pickerLabel!
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return (delegate as? FoodViewController)?.allCategories?[row][MenuCategoryTable.MenuCategory.CodingKeys.name.rawValue] as? String
    }
    
    // MARK: UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        return (delegate as? FoodViewController)?.allCategories?.count ?? 0
    }
    
}
