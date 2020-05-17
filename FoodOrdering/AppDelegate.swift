//
//  AppDelegate.swift
//  FoodOrdering
//
//  Created by fOrest on 2020/1/15.
//  Copyright © 2020 fOrest. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    static var shared: AppDelegate? {
        
        return UIApplication.shared.delegate as? AppDelegate
    }
    
    // global database object
    var dbWrapper: DbWrapper?
        
    func showAlertMessageWithActionOK(_ presenter: UIViewController?, _ title: String?, _ message: String?) ->Void {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        presenter?.present(alert, animated: true, completion: nil)
    }
    
    func showAlertMessageAutoDismiss(_ presenter: UIViewController, _ title: String?, _ message: String?, dismissAfter time: DispatchTime, _ completion: (() -> Void)? = nil) ->Void {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        presenter.present(alert, animated: true, completion: nil)
        
        DispatchQueue.main.asyncAfter(deadline: time) {
            
            alert.dismiss(animated: true, completion: completion)
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")

        do {
            
            try dbWrapper = DbWrapper.connect()
                                    
//            try dbWrapper?.drop(OrderBillTable.self)
//            try dbWrapper?.drop(OrderItemTable.self)
            
            if try !dbWrapper!.tableExists(MenuCategoryTable.self) {
                
                try dbWrapper?.create(MenuCategoryTable.self)
            }
            if try !dbWrapper!.tableExists(MenuItemTable.self) {
                
                try dbWrapper?.create(MenuItemTable.self)
            }
            if try !dbWrapper!.tableExists(OrderBillTable.self) {
                
                try dbWrapper?.create(OrderBillTable.self)
            }
            if try !dbWrapper!.tableExists(OrderItemTable.self) {
                
                try dbWrapper?.create(OrderItemTable.self)
            }
        }
        catch {
            
            debugPrint(error)
        }
        
        return true
    }
    

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        
        debugPrint("applicationWillResignActive")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
    }


    // MARK: UISceneSession Lifecycle
    
    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "FoodOrdering")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

extension DbWrapper {
    
    func tableExists(_ table: DatabaseTable.Type) throws ->Bool {
        
        var sqlString = "SELECT name FROM sqlite_master WHERE type='table' AND name='\(table.tableName)';"
        
        var statement = try prepare(for: sqlString)
        
        defer {
            
            if let statement = statement {
                sqlite3_finalize(statement)
            }
        }
        
        if sqlite3_step(statement) == SQLITE_ROW {
            
            return true
        }
        return false
    }
}
