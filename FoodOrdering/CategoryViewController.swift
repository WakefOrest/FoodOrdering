//
//  CategoryViewController.swift
//  FoodOrdering
//
//  Created by fOrest on 2020/4/28.
//  Copyright © 2020 fOrest. All rights reserved.
//

import UIKit

class CategoryViewController: UITableViewController, NewCategoryViewControllerDelegate, CategoryDetailViewControllerDelegate {
    
    var allCategories: [[String: Any?]]?
    
    func reloadData() {
        do {
            allCategories = try AppDelegate.shared?.dbWrapper?.read(from: MenuCategoryTable.self, where: nil, orderBy: nil)
            
        }catch {
            
            AppDelegate.shared?.showAlertMessageWithActionOK(self, error.localizedDescription, nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //
        reloadData()
    }
        
    func newCategoryAddSucceeded(_ sender: NewCategoryViewController) {
        
        AppDelegate.shared?.showAlertMessageAutoDismiss(self, "菜品种类添加成功", nil, dismissAfter: DispatchTime.now() + 0.8)
        
        reloadData()
        tableView.reloadData()

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "ShowNewCategory" {
            
            let destView = segue.destination as! NewCategoryViewController
            destView.delegate = self
        }
        if segue.identifier == "categoryDetailSegue" {
            let destView = segue.destination as! CategoryDetailViewController
            destView.delegate = self
            
            if let cell = (sender as? BasicSystemTableViewCell) {
                destView.currentCategory = cell.currentCategory
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell") as! BasicSystemTableViewCell
        
        if let categories = allCategories {
            
            let category = try! JSONDecoder().decode(MenuCategoryTable.MenuCategory.self, from: try JSONSerialization.data(withJSONObject: categories[indexPath.row], options: []))
            
            cell.titleLabel.text = String(describing: category.id) + "   " + category.name
            cell.currentCategory = category
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return allCategories?.count ?? 0
    }
    
    // MARK: CategoryDetailViewControllerDelegate
    
    func categoryDetailViewControllerChanged(sender: CategoryDetailViewController) {
        
        AppDelegate.shared?.showAlertMessageAutoDismiss(self, "品类修改成功！", nil, dismissAfter: DispatchTime.now() + 0.8)

        self.reloadData()
        self.tableView.reloadData()
    }
    
    func categoryDetailViewControllerDeleted(sender: CategoryDetailViewController) {
        
        AppDelegate.shared?.showAlertMessageAutoDismiss(self, "品类删除成功！", nil, dismissAfter: DispatchTime.now() + 0.8)

        self.reloadData()
        self.tableView.reloadData()
    }

}


class BasicSystemTableViewCell: UITableViewCell {
        
    @IBOutlet weak var titleLabel: UILabel!
    
    var currentCategory: MenuCategoryTable.MenuCategory?
}

protocol NewCategoryViewControllerDelegate {
    
    func newCategoryAddSucceeded(_ sender: NewCategoryViewController)
}

class NewCategoryViewController: UIViewController {
    
    @IBOutlet weak var categoryNameTextField: UITextField!
    
    @IBOutlet weak var categoryIDTextField: UITextField!
    
    var delegate: NewCategoryViewControllerDelegate?
    
    var currentCategory: MenuCategoryTable.MenuCategory?
    
    @IBAction func confirmButtonDidTouch(_ sender: Any) {
        
        let categoryName = categoryNameTextField.text
        //let categoryId = categoryIDTextField.text
        
        guard categoryName != ""  else {
            
            AppDelegate.shared?.showAlertMessageWithActionOK(self, "品类名称不能为空！", nil)
            return
        }
        
        do {
            try AppDelegate.shared?.dbWrapper?.insert(into: MenuCategoryTable.self, with: [MenuCategoryTable.MenuCategory.CodingKeys.name.rawValue: categoryName ?? "nil name inserted!"])
        }catch {
            
            debugPrint(error)
            //AppDelegate.shared?.showAlertMessageWithActionOK(self, error.localizedDescription, nil)
        }
        
        self.dismiss(animated: false) {
            
            self.delegate?.newCategoryAddSucceeded(self)
        }
    }
}


protocol CategoryDetailViewControllerDelegate {
    
    func categoryDetailViewControllerDeleted(sender: CategoryDetailViewController)
    func categoryDetailViewControllerChanged(sender: CategoryDetailViewController)
}


class CategoryDetailViewController: UIViewController {
    
    @IBOutlet weak var categoryIdTextField: UITextField!
    
    @IBOutlet weak var categoryNameTextField: UITextField!
    
    var currentCategory: MenuCategoryTable.MenuCategory?
    
    var delegate: CategoryDetailViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.categoryIdTextField.text = "\(self.currentCategory?.id ?? 0)"
        self.categoryNameTextField.text = "\(self.currentCategory?.name ?? "")"
    }
    
    @IBAction func deleteButtonDidTouch(_ sender: Any) {
       
        let alert = UIAlertController(title: "提示", message: "确定要删除分类吗？", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "取消", style: UIAlertAction.Style.default, handler: nil))
        alert.addAction(UIAlertAction(title: "删除", style: UIAlertAction.Style.destructive){ (action) in
            
            do {
                
                if (try AppDelegate.shared?.dbWrapper?.read(from: MenuItemTable.self, where: [MenuItemTable.MenuItem.CodingKeys.category.rawValue: self.currentCategory?.id ?? -1])) != nil {
                    
                    AppDelegate.shared?.showAlertMessageWithActionOK(self, "请先删除该品类下的所有菜品", nil)
                    return
                }
                
                try AppDelegate.shared?.dbWrapper?.delete(from: MenuCategoryTable.self, where: [MenuCategoryTable.MenuCategory.CodingKeys.id.rawValue: self.currentCategory?.id ?? -1])
                
                self.dismiss(animated: true) {
                    self.delegate?.categoryDetailViewControllerDeleted(sender: self)
                }
                
            }catch {
                AppDelegate.shared?.showAlertMessageWithActionOK(self, error.localizedDescription, nil)
            }
        })
        self.present(alert, animated: false)
    }
    
    @IBAction func confrimButtonDidTouch(_ sender: Any) {
       
        let categoryName = categoryNameTextField.text
        //let categoryId = categoryIDTextField.text
        
        guard (categoryName != nil) && (categoryName != "")   else {
            AppDelegate.shared?.showAlertMessageWithActionOK(self, "品类名称不能为空！", nil)
            return
        }
        
        do {
            try AppDelegate.shared?.dbWrapper?.update(MenuCategoryTable.self, with: [MenuCategoryTable.MenuCategory.CodingKeys.name.rawValue: categoryName ?? ""], where: [MenuCategoryTable.MenuCategory.CodingKeys.id.rawValue: self.currentCategory?.id ?? -1])
            
        }catch {
            
            debugPrint(error)
            //AppDelegate.shared?.showAlertMessageWithActionOK(self, error.localizedDescription, nil)
        }
        
        self.dismiss(animated: false) {
            self.delegate?.categoryDetailViewControllerChanged(sender: self)
        }
    }
}
