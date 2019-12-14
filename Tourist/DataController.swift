//
//  DataController.swift
//  Tourist
// DataController responsibility:
// 1. hold persistent container instance
// 2. load persistence store
// 3. access persistence contents
// Note: we want to use Data Controller as soon as app starts up so we call it in App Delegate
//
//  Created by William Lewis on 12/11/19.
//  Copyright © 2019 William Lewis. All rights reserved.
//
import Foundation
import CoreData

class DataController {
    /// create a simple singleton using static property type (guaranteed to be lazily initiated only once)
    static let sharedInstance = DataController()
    
    /// hold persistent instance
    let persistentContainer = NSPersistentContainer(name: "Tourist")
     
    /// a convenience property to access the containers view context
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
   
    func load() {
        persistentContainer.loadPersistentStores { storeDescription, error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            /// kicks off initial autosave
            self.autoSaveViewContext()
           
        }
    }
    
}

// MARK: - Autosaving

extension DataController {
    func autoSaveViewContext(interval:TimeInterval = 30) {
        print("autosaving")

        guard interval > 0 else {
            print("cannot set negative autosave interval")
            return
        }

        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                /// replace this implementation with code to handle the error appropriately.
                let nserror = error as NSError
                fatalError("Unresolved error saving \(nserror), \(nserror.localizedDescription)")
            }
        }
        /// call autosave after specified interval has elapsed
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.autoSaveViewContext(interval: interval)
        }
    }
}
