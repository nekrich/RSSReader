//
//  CoreDataHelper.swift
//  RSSReader
//
//  Created by Vitalii Budnik on 5/4/16.
//  Copyright © 2016 org. All rights reserved.
//

import Foundation
import CoreData
import UIKit

/**
 Easy `CoreData`.
 */
public final class CoreDataHelper {
  
  /**
   Initializes instance with passed `modelName` and `fileName`. Adds observers of application state
   
   - parameter modelName: `String` with .xcdatamodeld filename (without extension)
   - parameter fileName: `String` with filename of created CoreData storage
   
   Returns initialized `self`
   */
  private init(withModelName modelName: String, fileName: String) {
    self.modelName = modelName
    self.fileName = fileName
    
    applicationDidEnterBackgroundObserver = NSNotificationCenter.defaultCenter().addObserverForName(
      UIApplicationDidEnterBackgroundNotification,
      object: .None,
      queue: .None) { [weak self] _ in
        self?.save()
    }
    
    applicationWillTerminateObserver = NSNotificationCenter.defaultCenter().addObserverForName(
      UIApplicationWillTerminateNotification,
      object: .None,
      queue: .None) { [weak self] _ in
        self?.save()
    }
    
  }
  
  /// `UIApplicationDidEnterBackgroundNotification` notification observer
  private var applicationDidEnterBackgroundObserver: NSObjectProtocol? = .None
  
  /// `UIApplicationWillTerminateNotification` notification observer
  private var applicationWillTerminateObserver: NSObjectProtocol? = .None
  
  /**
   Attempts to commit unsaved changes in `managedObjectContext`. Recursively for all `parentContext`'s.
   Public for application state observers
   */
  private func save() {
    saveContext()
  }
  
  /**
   Deinitializes `self`. Removes observers of application state
   */
  deinit {
    
    if let applicationDidEnterBackgroundObserver = applicationDidEnterBackgroundObserver {
      NSNotificationCenter.defaultCenter().removeObserver(
        applicationDidEnterBackgroundObserver,
        name: UIApplicationDidEnterBackgroundNotification,
        object: .None)
      self.applicationDidEnterBackgroundObserver = .None
    }
    
    if let applicationWillTerminateObserver = applicationWillTerminateObserver {
      NSNotificationCenter.defaultCenter().removeObserver(
        applicationWillTerminateObserver,
        name: UIApplicationWillTerminateNotification,
        object: .None)
      self.applicationWillTerminateObserver = .None
    }
    
  }
  
  /// `String` with .xcdatamodeld filename (without extension). (read-only)
  private let modelName: String
  
  /// `String` with filename of created CoreData storage. (read-only)
  private let fileName: String
  
  // MARK: Core Data stack
  /// Application library directory `NSURL`
  private lazy var applicationLibraryDirectory: NSURL = {
    // The directory the application uses to store the Core Data store file.
    // This code uses a directory named "com.gms-worldwide.GMS_Worldwide" in the application's
    // documents Application Support directory.
    let urls = NSFileManager.defaultManager().URLsForDirectory(
      .LibraryDirectory,
      inDomains: .UserDomainMask)
    return urls[urls.count-1]
  }()
  
  /// The managed object model for the framework
  private lazy var managedObjectModel: NSManagedObjectModel = {
    // The managed object model for the framework. This property is not optional.
    // It is a fatal error for the application not to be able to find and load its model.
    let bundle = NSBundle(forClass: self.dynamicType)
    let modelURL = bundle.URLForResource(modelName, withExtension: "momd")!
    return NSManagedObjectModel(contentsOfURL: modelURL)!
  }()
  
  /// The persistent store coordinator for the framework
  private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
    // The persistent store coordinator for the framework. This implementation creates and returns
    // a coordinator, having added the store for the application to it. This property is optional since there
    // are legitimate error conditions that could cause the creation of the store to fail.
    // Create the coordinator and store
    let coordinator = NSPersistentStoreCoordinator(
      managedObjectModel: self.managedObjectModel)
    
    let url = self.applicationLibraryDirectory.URLByAppendingPathComponent(
      fileName + ".sqlite")
    
    var failureReason = "There was an error creating or loading the application's saved data."
    do {
      try coordinator.addPersistentStoreWithType(
        NSSQLiteStoreType,
        configuration: nil,
        URL: url,
        options: nil)
    } catch {
      // Report any error we got.
      var dict = [String: AnyObject]()
      dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
      dict[NSLocalizedFailureReasonErrorKey] = failureReason
      //      if error is NSError {
      //        dict[NSUnderlyingErrorKey] = error
      //      }
      let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
      // TODO: Logger
    }
    
    return coordinator
  }()
  
  /// Returns the main managed object context for the framework (which is already bound
  /// to the persistent store coordinator for the framework.)
  /// Private property
  private lazy var mainManagedObjectContext: NSManagedObjectContext = {
    // Returns the managed object context for the application (which is already bound to the persistent store
    // coordinator for the application.) This property is optional since there are legitimate error conditions
    // that could cause the creation of the context to fail.
    let coordinator = self.persistentStoreCoordinator
    var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
    managedObjectContext.persistentStoreCoordinator = coordinator
    return managedObjectContext
  }()
  
  /// Returns the main managed object context for the framework (which is already bound to the persistent
  /// store coordinator for the framework.)
  /// Private property
  private lazy var managedObjectContext: NSManagedObjectContext = {
    // Returns the managed object context for the application (which is already bound to the persistent store
    // coordinator for the application.) This property is optional since there are legitimate error conditions
    // that could cause the creation of the context to fail.
    var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
    managedObjectContext.parentContext = mainManagedObjectContext
    return managedObjectContext
  }()
  
}

internal extension CoreDataHelper {
  
  /// `String` with .xcdatamodeld filename (without extension)
  private static var modelName: String = "RSSReader"
  
  /// `String` with filename of created CoreData storage
  private static var fileName: String = modelName
  
  /**
   Sets static `modelName` and `fileName` variables, used to initalize shared instance of
   `CoreDataHelper
   
   - parameter modelName: `String` with .xcdatamodeld filename (without extension)
   - parameter fileName: `String` with filename of created CoreData storage
   - warning: You should call this func before first access to `sharedInstance` property
   */
  internal static func initializeSharedInstance(
    withModelName modelName: String,
    fileName: String)
  {
    CoreDataHelper.modelName = modelName
    CoreDataHelper.fileName = fileName
  }
  
  /**
   Generates new `NSManagedObjectContext` for current thread
   - returns: Newely generated `NSManagedObjectContext` for current thread
   */
  internal func newManagedObjectContext() -> NSManagedObjectContext {
    let moc = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
    moc.parentContext = managedObjectContext
    return moc
  }
  
  // Core Data Saving support
  /**
   Attempts to commit unsaved changes in `managedObjectContext`. Recursively for all `parentContext`'s
   */
  internal func saveContext() {
    managedObjectContext.performBlockAndWait {
      if self.managedObjectContext.hasChanges {
        do {
          try self.managedObjectContext.saveRecursively()
        } catch {
          let wrappedError = error as NSError
          print(wrappedError)
          // TODO: Logger
        }
      }
    }
  }
  
}

// MARK: - Static
extension CoreDataHelper {
  
  /// The shared `CoreDataHelper` object for the process. (read-only)
  private (set) static var sharedInstance: CoreDataHelper = {
    return CoreDataHelper(withModelName: modelName, fileName: fileName)
  }()
  
  /// The shared `CoreDataHelper` object for the process. (read-only)
  private static var mainManagedObjectContext: NSManagedObjectContext {
    return sharedInstance.mainManagedObjectContext
  }
  
  /// Returns the main managed object context for the framework
  /// (which is already bound to the persistent store coordinator for the framework.). (read-only)
  static var managedObjectContext: NSManagedObjectContext {
    return sharedInstance.managedObjectContext
  }
  
  /// The managed object model for the framework. (read-only)
  static var managedObjectModel: NSManagedObjectModel {
    return sharedInstance.managedObjectModel
  }
  
  /**
   Generates new `NSManagedObjectContext` for current thread
   - returns: Newely generated `NSManagedObjectContext` for current thread
   */
  static func newManagedObjectContext() -> NSManagedObjectContext {
    return sharedInstance.newManagedObjectContext()
  }
  
  // MARK: Core Data Saving support
  /**
   Attempts to commit unsaved changes in `managedObjectContext`. Recursively for all `parentContext`'s
   */
  static func saveContext() {
    sharedInstance.saveContext()
  }
  
}

private extension NSManagedObjectContext {
  
  /**
   Saves `self` recursively and waits for response (uses all `parentContext`s)
   - Throws: `NSError`
   */
  func saveRecursively() throws {
    
    guard hasChanges else { return }
    
    var saveError: ErrorType? = .None
    
    performBlockAndWait() {
      do {
        try self.save()
      } catch {
        saveError = error
      }
    }
    if let saveError = saveError {
      throw saveError
    }
    
    if let parentContext = parentContext {
      try parentContext.saveRecursively()
    }
    
  }
  
}
