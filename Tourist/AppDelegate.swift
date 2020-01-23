//
//  AppDelegate.swift
//  Tourist
//
//  Created by William Lewis on 12/11/19.
//  Copyright © 2019 William Lewis. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        DataController.sharedInstance.load()
        return true
    }

    
    
    
    

}

