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
   
    //1. hold persistent instance
    let persistentContainer: NSPersistentContainer
     
    //3. A convenience property to access the containers view context
    //its a computed property
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    //FIXME: BackgroundContext
    let backgroundContext: NSManagedObjectContext!
    
    //4. initializes persistence store and pass model name into its initializer
    init(modelName: String) {
        persistentContainer = NSPersistentContainer(name: modelName)
        
        //FIXME: BackgroundContext2
        backgroundContext = persistentContainer.newBackgroundContext()
    }
    
    // handle merges if we edit our model
    func configureContexts() {
        viewContext.automaticallyMergesChangesFromParent = true
        //FIXME: BackgroundContex3
        backgroundContext.automaticallyMergesChangesFromParent = true
        
        //FIXME: BackgroundContext4
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
    }
    //2. load persistence store
    //it can accept a completion which is an optional that defaults to nil
    func load(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores { storeDescription, error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            //kicks off initial autosave
            self.autoSaveViewContext()
            self.configureContexts()
            completion?()
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
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error saving \(nserror), \(nserror.localizedDescription)")
            }
        }
        //call autosave after specified interval has elapsed
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.autoSaveViewContext(interval: interval)
        }
    }
}
