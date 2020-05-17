//
//  SqlWrapper.swift
//  FoodOrdering
//
//  Created by fOrest on 2020/1/28.
//  Copyright © 2020 fOrest. All rights reserved.
//

import Foundation

enum SqlQueryOrder: String {
    case ASC, DESC
}

enum SqlError: Error {
    case Connect(error: String)
    case Prepare(error: String)
    case Step(error: String)
    case Bind(error: String)
}

class DbWrapper {
    
    private let dbPointer: OpaquePointer?
        
    init(_ dbPointer: OpaquePointer?) {
        
        self.dbPointer = dbPointer
    }
    
    deinit {
        
        if let pointer = self.dbPointer {
            sqlite3_close_v2(pointer)
        }
    }
    
    static func connect() throws -> DbWrapper? {
        
        var db: OpaquePointer? = nil
        
        let fileManager = FileManager.default
        var baseUrl: URL? = nil
        
        do {
            baseUrl = try fileManager.url(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask, appropriateFor: nil, create: false)
        }catch {
            
            throw SqlError.Connect(error: "connect error: \(error.localizedDescription)")
        }
        
        let dbUrl = baseUrl!.appendingPathComponent("mydatabase").appendingPathExtension("sqlite")
        
        guard sqlite3_open_v2(dbUrl.absoluteString.cString(using: String.Encoding.utf8), &db, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE, nil) == SQLITE_OK else {
            if let pointer = db {
                sqlite3_close_v2(pointer)
            }
            throw SqlError.Connect(error: "connect error: sqlite open failed!")
        }
        return DbWrapper(db)
    }
    
    var sqlErrorMessage: String? {
        if let pointer = sqlite3_errmsg(self.dbPointer) {
            return String(cString: pointer)
        } else {
            return nil
        }
    }
    
    func prepare(for statement: String) throws -> OpaquePointer? {
        
        var sqlStatement: OpaquePointer?
        guard sqlite3_prepare_v2(self.dbPointer, statement.cString(using: String.Encoding.utf8), -1, &sqlStatement, nil) == SQLITE_OK else {
            
            throw SqlError.Prepare(error: "prepare error :\(sqlErrorMessage ?? "no error message  available from sqlite")")
        }
        return sqlStatement
    }
    
    func step(_ statement: OpaquePointer) throws {
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            
            throw SqlError.Step(error: "step error: \(sqlErrorMessage ?? "no error message  available from sqlite")")
        }
    }
    
    func create(_ table: DatabaseTable.Type) throws {
        
        let createString = table.createString
        var createStatement = try prepare(for: createString)
        
        defer {
            if let statement = createStatement {
                sqlite3_finalize(statement)
            }
        }
        
        if let statement = createStatement {
            try step(statement)
        }
    }
    
    func drop(_ table: DatabaseTable.Type) throws {
        
        let dropString = "DROP TABLE \(table.tableName)"
        var dropStatement = try prepare(for: dropString)
        
        defer {
            if let statement = dropStatement {
                sqlite3_finalize(statement)
            }
        }
        
        if let statement = dropStatement {
            try step(statement)
        }

    }
    
    func insert(_ item: TableItem, into table: DatabaseTable.Type) throws {
        
        var insertString: String = "INSERT INTO \(table.tableName)" + "("
        
        guard let values = item.values else {
            return
        }
        for key in values.keys {
            
            insertString += "\(key), "
        }
        insertString = insertString.trimmingCharacters(in: CharacterSet(charactersIn: ", "))
        insertString += ") VALUES("
        for value in values.values {
            if value is String {
                insertString += "\(String(describing: "'" + (value as! String) + "'")), "
            } else {
            insertString += "\(String(describing: value)), "
            }
        }
        insertString = insertString.trimmingCharacters(in: CharacterSet(charactersIn: ", "))
        insertString += ");"
        
        var insertStatement = try prepare(for: insertString)
        
        defer {
            
            if let statement = insertStatement {
                sqlite3_finalize(statement)
            }
        }
        
        if let statement = insertStatement {
            try step(statement)
        }
    }
    
    func insert(into table: DatabaseTable.Type, with columnValues: [String: Any]) throws {
        
        var insertString: String = "INSERT INTO \(table.tableName)" + "("
        
        let values = columnValues
        
        for key in values.keys {
            
            insertString += "\(key), "
        }
        insertString = insertString.trimmingCharacters(in: CharacterSet(charactersIn: ", "))
        insertString += ") VALUES("
        for value in values.values {
            if value is String {
                insertString += "\(String(describing: "'" + (value as! String) + "'")), "
            } else {
            insertString += "\(String(describing: value)), "
            }
        }
        insertString = insertString.trimmingCharacters(in: CharacterSet(charactersIn: ", "))
        insertString += ");"
        
        var insertStatement = try prepare(for: insertString)
        
        defer {
            
            if let statement = insertStatement {
                sqlite3_finalize(statement)
            }
        }
        
        if let statement = insertStatement {
            try step(statement)
        }
    }
    
    func update(_ item: TableItem, from table: DatabaseTable.Type) throws {
        
        var updateString: String = "UPDATE \(table.tableName) SET "
        if let values = item.values {
            for (key, value) in values where key != table.primaryKey {
                
                if value is String {
                    updateString += "\(key) = \(String(describing: "'" + (value as! String) + "'")), "
                } else {
                updateString += "\(key) = \(String(describing: value)), "
                }
            }
            updateString = updateString.trimmingCharacters(in: CharacterSet(charactersIn: ", "))
            
            if values[table.primaryKey] is String {
                updateString += " WHERE \(table.primaryKey) = \(String(describing: "'" + (values[table.primaryKey] as! String) + "'"));"
            } else {
            updateString += " WHERE \(table.primaryKey) = \(String(describing: values[table.primaryKey]!));"
            }
            
        } else {
            return
        }
        
        var updateStatement = try prepare(for: updateString)
        
        defer {
            
            if let statement = updateStatement {
                sqlite3_finalize(statement)
            }
        }
        
        if let statement = updateStatement {
            try step(statement)
        }
    }
    
    func update(_ table: DatabaseTable.Type, with columnValues: [String: Any], where keyValues: [String: Any]) throws {
        
        var updateString: String = "UPDATE \(table.tableName) SET "
        for (key, value) in columnValues{
            
            if value is String {
                updateString += "\(key) = \(String(describing: "'" + (value as! String) + "'")), "
            } else {
            updateString += "\(key) = \(String(describing: value)), "
            }
        }
        updateString = updateString.trimmingCharacters(in: CharacterSet(charactersIn: ", "))
        updateString += " WHERE "
        for (key, value) in keyValues {
            
            if value is String {
                updateString += "\(key) = \(String(describing: "'" + (value as! String) + "'"))" + " AND "
            } else {
            updateString += "\(key) = \(String(describing: value))" + " AND "
            }
            
        }
        updateString = updateString.trimmingCharacters(in: CharacterSet(charactersIn: " AND "))
        updateString += ";"
        
        var updateStatement = try prepare(for: updateString)
        
        defer {
            
            if let statement = updateStatement {
                sqlite3_finalize(statement)
            }
        }
        
        if let statement = updateStatement {
            try step(statement)
        }
    }
    
    
    func read(from table: DatabaseTable.Type , by conditions: String?,  orderBy keyOrders: [(String, SqlQueryOrder)]? = nil) throws -> [[String: Any?]]? {
        
        var selectString = "SELECT * FROM \(table.tableName)"
        if let conditions = conditions {
            selectString += " WHERE \(conditions)"
        }
        if let keyOrders = keyOrders {
            selectString += " ORDER BY "
            for (key, order) in keyOrders {
                selectString += "\(key) \(order.rawValue), "
            }
            selectString = selectString.trimmingCharacters(in: CharacterSet(charactersIn: ", "))
        }
        
        selectString += ";"
        
        var selectStatement = try prepare(for: selectString)
        
        defer {
            
            if let statement = selectStatement {
                sqlite3_finalize(statement)
            }
        }
                        
        let columnCount = sqlite3_column_count(selectStatement)
        var values: [[String: Any?]] = [[String: Any?]]()
        
        while sqlite3_step(selectStatement) == SQLITE_ROW {
            
            var keyValues: [String: Any?] = Dictionary<String, Any?>.init()
            for iCol in 0...(columnCount - 1) {
                
                let name = String(cString: sqlite3_column_name(selectStatement, iCol))
                let type = sqlite3_column_type(selectStatement, iCol)
                var value: Any?
                if type == SQLITE_INTEGER {
                    
                    value = sqlite3_column_int64(selectStatement, iCol)
                } else if type == SQLITE_FLOAT {
                    
                    value = sqlite3_column_double(selectStatement, iCol)
                }
                else if type == SQLITE_TEXT {
                    
                    value = String(cString: sqlite3_column_text(selectStatement, iCol))
                } else if type == SQLITE_BLOB {
                    
                    value = sqlite3_column_blob(selectStatement, iCol)
                }
                else if type == SQLITE_NULL {
                    value = nil
                }
                try keyValues.merge([name : value]) { _,_ in
                    throw SqlError.Step(error: "key name error")
                }
            }
            values.append(keyValues)
        }
        
        if values.isEmpty {
            return nil
        }
        return values
    }
    
    func read(from table: DatabaseTable.Type, where keyValues: [String: Any]?, orderBy keyOrders: [(String, SqlQueryOrder)]? = nil) throws -> [[String: Any?]]? {
        
        var selectString = "SELECT * FROM \(table.tableName)"
        if let keyValues = keyValues {
            selectString += " WHERE "
            for (key, value) in keyValues {
                
                if value is String {
                    selectString += "\(key) = \(String(describing: "'" + (value as! String) + "'"))" + " AND "
                } else {
                    selectString += "\(key) = \(String(describing: value))" + " AND "
                }
            }
            selectString = selectString.trimmingCharacters(in: CharacterSet(charactersIn: " AND "))
        }
        if let keyOrders = keyOrders {
            selectString += " ORDER BY "
            for (key, order) in keyOrders {
                selectString += "\(key) \(order.rawValue), "
            }
            selectString = selectString.trimmingCharacters(in: CharacterSet(charactersIn: ", "))
        }
        
        selectString += ";"
        
        var selectStatement = try prepare(for: selectString)
        
        defer {
            
            if let statement = selectStatement {
                sqlite3_finalize(statement)
            }
        }
                        
        let columnCount = sqlite3_column_count(selectStatement)
        var values: [[String: Any?]] = [[String: Any?]]()
        
        while sqlite3_step(selectStatement) == SQLITE_ROW {
            
            var keyValues: [String: Any?] = Dictionary<String, Any?>.init()
            for iCol in 0...(columnCount - 1) {
                
                let name = String(cString: sqlite3_column_name(selectStatement, iCol))
                let type = sqlite3_column_type(selectStatement, iCol)
                var value: Any?
                if type == SQLITE_INTEGER {
                    
                    value = sqlite3_column_int64(selectStatement, iCol)
                } else if type == SQLITE_FLOAT {
                    
                    value = sqlite3_column_double(selectStatement, iCol)
                }
                else if type == SQLITE_TEXT {
                    
                    value = String(cString: sqlite3_column_text(selectStatement, iCol))
                } else if type == SQLITE_BLOB {
                    
                    value = sqlite3_column_blob(selectStatement, iCol)
                }
                else if type == SQLITE_NULL {
                    value = nil
                }
                try keyValues.merge([name : value]) { _,_ in
                    throw SqlError.Step(error: "key name error")
                }
            }
            values.append(keyValues)
        }
        
        if values.isEmpty {
            return nil
        }
        return values
    }
    
    func delete(from table: DatabaseTable.Type, where keyValues: [String: Any]?) throws -> Void {
        
        var deleteString = "DELETE FROM \(table.tableName)"
        if let keyValues = keyValues {
            deleteString += " WHERE "
            for (key, value) in keyValues {
                if value is String {
                    deleteString += "\(key) = \(String(describing: "'" + (value as! String) + "'"))" + " AND "
                }else {
                    deleteString += "\(key) = \(String(describing: value))" + " AND "
                }
            }
            deleteString.removeLast(5)
            //deleteString = deleteString.trimmingCharacters(in: CharacterSet(charactersIn: " AND "))
        }
        deleteString += ";";
        
        var deleteStatement = try prepare(for: deleteString)
        
        defer {
            
            if let statement = deleteStatement {
                sqlite3_finalize(statement)
            }
        }
        
        if let statement = deleteStatement {
            try step(statement)
        }
    }
    
    func delete(_ item: TableItem, from table: DatabaseTable.Type) throws -> Void {
        
        var deleteString = "DELETE FROM \(table.tableName) "
        
        if let values = item.values {
            
            if values[table.primaryKey] is String {
                deleteString += "WHERE \(table.primaryKey) = \(String(describing: "'" + (values[table.primaryKey] as! String) + "'"));"
            }else {
                deleteString += "WHERE \(table.primaryKey) = \(String(describing: values[table.primaryKey]));"
            }
            
        }
        
        var deleteStatement = try prepare(for: deleteString)
        
        defer {
            
            if let statement = deleteStatement {
                sqlite3_finalize(statement)
            }
        }
        
        if let statement = deleteStatement {
            try step(statement)
        }
    }
}
