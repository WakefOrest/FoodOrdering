//
//  CustomOrder.swift
//  FoodOrdering
//
//  Created by fOrest on 2020/1/23.
//  Copyright © 2020 fOrest. All rights reserved.
//

import Foundation

protocol TableItem: Codable {
    
    var values: [String: Any]? { get }
}

protocol DatabaseTable {
    
    static var createString: String { get }
    
    static var primaryKey: String { get }
    
    static var tableName: String { get }
}

/*
 * Menu Category Table
 * categoryId:      Int64       unique integer that identifies a menu category
 * cateName:    Text        name of a menu category for UI displays
 * enabled:     Boolean     indicates whether a menu category is available
 ***************************************************************************
 */

class MenuCategoryTable : DatabaseTable {
    
    struct MenuCategory: TableItem {
        
        var id: Int64
        var name: String
                
        enum CodingKeys: String, CodingKey {
            case id, name
        }
        
        public var values: [String: Any]? {
            
            return try? JSONSerialization.jsonObject(with: try!
                JSONEncoder().encode(self), options:[]) as? [String: Any]
        }
    }
            
    static var tableName: String {
        
        return String(describing: MenuCategory.self)
    }
    
    static var primaryKey: String {
        
        return MenuCategory.CodingKeys.id.rawValue
    }
        
    static var createString: String {
        return """
        CREATE TABLE \(MenuCategoryTable.tableName)(
        \(MenuCategory.CodingKeys.id.rawValue)           INTEGER         PRIMARY KEY    AUTOINCREMENT     NOT NULL,
        \(MenuCategory.CodingKeys.name.rawValue)         TEXT        NOT NULL
        );
        """
    }
        
}

/*
 * Menu Item Table
 * itemId:      Int64       unique integer that identifies a menu category
 * itemName:    Text        name of a menu category for UI displays
 * category:    Int64       category ID of the item
 * price:       Double     item price
 * enabled:     Boolean     indicates whether a menu item is usable
 ***************************************************************************/
 
struct MenuItemTable: DatabaseTable {

    struct MenuItem: TableItem {
        
        var id: Int64
        var name: String
        var category: Int64
        var price: Double
        var enabled: Bool = true
        
        enum CodingKeys: String, CodingKey {
            
            case id, name, category, price, enabled
        }
        
        init(id: Int64, name: String, category: Int64, price: Double, enabled: Bool) {
            self.id = id; self.name = name; self.category = category; self.price = price; self.enabled = enabled
        }
        
        init(from decoder: Decoder) throws {
            
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.id = try (container.decodeIfPresent(Int64.self, forKey: .id) ?? 0)
            self.name = try (container.decodeIfPresent(String.self, forKey: .name) ?? "")
            self.category = try (container.decodeIfPresent(Int64.self, forKey: .category) ?? 0)
            self.price = try (container.decodeIfPresent(Double.self, forKey: .price) ?? 0.0)
            
            do {
                self.enabled = try (container.decodeIfPresent(Bool.self, forKey: .enabled) ?? true)
                
            } catch DecodingError.typeMismatch {

                if let value = try container.decodeIfPresent(Int.self, forKey: .enabled) {
                    
                    self.enabled = (value == 0) ? false : true
                }
            }
        }
        
        var values: [String : Any]? {
            
            return try? JSONSerialization.jsonObject(with: try! JSONEncoder().encode(self), options: []) as? [String: Any]
        }
    }
    
    static var tableName: String {
        return String(describing: MenuItem.self)
    }
    
    static var primaryKey: String {
        
        return MenuItem.CodingKeys.id.rawValue
    }

    static var createString: String {
        return """
        CREATE TABLE \(MenuItemTable.tableName)(
        \(MenuItem.CodingKeys.id.rawValue)          INTEGER         PRIMARY KEY     AUTOINCREMENT         NOT NULL,
        \(MenuItem.CodingKeys.name.rawValue)        TEXT                            NOT NULL,
        \(MenuItem.CodingKeys.category.rawValue)    INT                             NOT NULL,
        \(MenuItem.CodingKeys.price.rawValue)       REAL                            NOT NULL,
        \(MenuItem.CodingKeys.enabled.rawValue)     BOOLEAN                         NOT NULL,
        FOREIGN KEY(\(MenuItem.CodingKeys.category.rawValue)) REFERENCES \(MenuCategoryTable.tableName)(\(String(describing: MenuCategoryTable.primaryKey)))
        );
        """
    }

}

/*
 * Order Bill Table
 * orderId:      Int64       unique integer that identifies an order
 * orderName:    Text        name by describing, optional
 * table:        Int64       table number, optional
 * remarks:      Text        provide more information about the order, optional
 * createStamp   DateTime    timestamp of creation
 * finishStamp   DateTime    timestamp of finish
 * finished:     Boolean     indicates whether an order is finished/payed, false as default
 * cancelled:    Boolean     indicates whether an order is cancelled, false as default
 ***************************************************************************
 */
struct OrderBillTable: DatabaseTable {
    
    struct OrderBill: TableItem {
        
        var id: Int64
        var name: String?
        var tableNO: Int64?
        var remarks: String?
        var createStamp: TimeInterval
        var finishStamp: TimeInterval?
        var finished: Bool = false
        var cancelled: Bool = false
        var takeAway: Bool = false
        var dilivery: Bool = false
        
        enum CodingKeys: String, CodingKey {
            
            case id, name, tableNO, remarks, createStamp, finishStamp, finished, cancelled, takeAway, dilivery
        }
        
        
        init(id: Int64, name: String?, tableNO: Int64, remarks: String?, createStamp: Double, finishStamp: Double?, finished: Bool, cancelled: Bool, takeAway: Bool, dilivery: Bool) {
            self.id = id; self.name = name; self.tableNO = tableNO; self.remarks = remarks; self.createStamp = createStamp; self.finishStamp = finishStamp; self.finished = finished;self.cancelled = cancelled;self.takeAway = takeAway;self.dilivery = dilivery
        }
        
        init(from decoder: Decoder) throws {
            
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.id = try (container.decodeIfPresent(Int64.self, forKey: .id) ?? 0)
            self.name = try (container.decodeIfPresent(String.self, forKey: .name) ?? "")
            self.tableNO = try (container.decodeIfPresent(Int64.self, forKey: .tableNO) ?? 0)
            self.remarks = try (container.decodeIfPresent(String.self, forKey: .remarks) ?? "")
            self.createStamp = try (container.decodeIfPresent(Double.self, forKey: .createStamp) ?? 0.0)
            self.finishStamp = try (container.decodeIfPresent(Double.self, forKey: .finishStamp) ?? 0.0)
            
            do {
                self.finished = try (container.decodeIfPresent(Bool.self, forKey: .finished) ?? true)
                
            } catch DecodingError.typeMismatch {

                if let value = try container.decodeIfPresent(Int.self, forKey: .finished) {
                    
                    self.finished = (value == 0) ? false : true
                }
            }
            do {
                self.cancelled = try (container.decodeIfPresent(Bool.self, forKey: .cancelled) ?? true)
                
            } catch DecodingError.typeMismatch {

                if let value = try container.decodeIfPresent(Int.self, forKey: .cancelled) {
                    
                    self.cancelled = (value == 0) ? false : true
                }
            }
            do {
                self.takeAway = try (container.decodeIfPresent(Bool.self, forKey: .takeAway) ?? true)
                
            } catch DecodingError.typeMismatch {

                if let value = try container.decodeIfPresent(Int.self, forKey: .takeAway) {
                    
                    self.takeAway = (value == 0) ? false : true
                }
            }
            do {
                self.dilivery = try (container.decodeIfPresent(Bool.self, forKey: .dilivery) ?? true)
                
            } catch DecodingError.typeMismatch {

                if let value = try container.decodeIfPresent(Int.self, forKey: .dilivery) {
                    
                    self.dilivery = (value == 0) ? false : true
                }
            }
        }
        
        var values: [String : Any]? {
            
            return try? JSONSerialization.jsonObject(with: try! JSONEncoder().encode(self), options: []) as? [String: Any]
        }
    }

    static var tableName: String {

        return String(describing: OrderBill.self)
    }
    
    static var primaryKey: String {
        return OrderBill.CodingKeys.id.rawValue
    }
    
    static var createString: String {
        return """
        CREATE TABLE \(OrderBillTable.tableName)(
            \(OrderBill.CodingKeys.id.rawValue)              INTEGER     PRIMARY KEY     AUTOINCREMENT       NOT NULL,
            \(OrderBill.CodingKeys.name.rawValue)            TEXT                                    ,
            \(OrderBill.CodingKeys.tableNO.rawValue)         INT                                     ,
            \(OrderBill.CodingKeys.remarks.rawValue)         TEXT                                    ,
            \(OrderBill.CodingKeys.createStamp.rawValue)     DATETIME                        NOT NULL,
            \(OrderBill.CodingKeys.finishStamp.rawValue)     DATETIME                                ,
            \(OrderBill.CodingKeys.finished.rawValue)        BOOLEAN                         NOT NULL,
            \(OrderBill.CodingKeys.cancelled.rawValue)       BOOLEAN                         NOT NULL,
            \(OrderBill.CodingKeys.takeAway.rawValue)        BOOLEAN                         NOT NULL,
            \(OrderBill.CodingKeys.dilivery.rawValue)        BOOLEAN                         NOT NULL
        );
        """
    }
}


/*
 * Order Item Table
 * orderId:      Int64       order the item from
 * itemName:     Text        name of item,usually from a menu item
 * remarks:      Text        provide more information about the order
 * timestamp     DateTime    timestamp of creation
 * price:        Double     item price when creating
 * count:        Boolean     item count
 ***************************************************************************
 */
struct OrderItemTable: DatabaseTable {
    
    struct OrderItem: TableItem {
        
        var serial: Int64
        var orderId: Int64
        var itemId: Int64?
        var itemName: String
        var remarks: String?
        var count: Int64
        var price: Double
        var timestamp: TimeInterval
        
        enum CodingKeys: String, CodingKey {
            case serial, orderId, itemId, itemName, remarks, count, price, timestamp
        }
        
        var values: [String : Any]? {
            
            return try? JSONSerialization.jsonObject(with: try! JSONEncoder().encode(self), options: []) as? [String: Any]
        }
    }

    static var tableName: String {
        
        return String(describing: OrderItem.self)
    }
    
    static var primaryKey: String {
        
        return OrderItem.CodingKeys.serial.rawValue
    }

    static var createString: String {
        return """
        CREATE TABLE \(OrderItemTable.tableName)(
            \(OrderItem.CodingKeys.serial.rawValue)          INTEGER     PRIMARY KEY     AUTOINCREMENT        NOT NULL,
            \(OrderItem.CodingKeys.orderId.rawValue)         INT                             NOT NULL,
            \(OrderItem.CodingKeys.itemId.rawValue)          INT                            ,
            \(OrderItem.CodingKeys.itemName.rawValue)        TEXT                            NOT NULL,
            \(OrderItem.CodingKeys.remarks.rawValue)         TEXT                                    ,
            \(OrderItem.CodingKeys.count.rawValue)           INT                                     ,
            \(OrderItem.CodingKeys.price.rawValue)           REAL                            NOT NULL,
            \(OrderItem.CodingKeys.timestamp.rawValue)       DATETIME                        NOT NULL,
        FOREIGN KEY(\(OrderItem.CodingKeys.orderId.rawValue)) REFERENCES \(OrderBillTable.tableName)(\(String(describing: OrderBillTable.primaryKey)))
        );
        """
    }
}

