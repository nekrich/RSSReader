//
//  TableViewControllerWithFetchedResultsController.swift
//  RSSReader
//
//  Created by Vitalii Budnik on 5/4/16.
//  Copyright © 2016 org. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class UITableViewControllerWithFetchedResultsController: UITableViewController {
  
  var managedObjectContext: NSManagedObjectContext = CoreDataHelper.managedObjectContext {
    didSet {
      reFetchResults(true)
    }
  }
  
  private var _fetchedResultsController: NSFetchedResultsController? = .None
  
  var predicate: NSPredicate? = .None {
    didSet {
      if _fetchedResultsController == nil {
        return
      }
      fetchedResultsController.fetchRequest.predicate = predicate
      reloadFetchedResultsControllerData(true)
    }
  }
  
  var sortDescriptors: [NSSortDescriptor] = [] {
    didSet {
      fetchedResultsController.fetchRequest.sortDescriptors = sortDescriptors
      reloadFetchedResultsControllerData(true, reloadData: true)
    }
  }
  
  lazy var reusableCellIdentifier: String = {
    return self.entityName + "Cell"
  }()
  
  lazy var entityName: String = {
    let entityName = NSStringFromClass(self.dynamicType)
      .componentsSeparatedByString(".")
      .last!
      .stringByReplacingOccurrencesOfString("sTableViewController", withString: "")
    return entityName
  }()
  
  var cacheName: String? {
    return "Master"
  }
  
  override func viewDidLoad() {
    clearCache()
    super.viewDidLoad()
  }
  
  
}

// MARK: - UITableViewDataSource
extension UITableViewControllerWithFetchedResultsController {
  
  // MARK: count
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return fetchedResultsController.sections?.count ?? 1
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return fetchedResultsController.sections?[section].numberOfObjects ?? 0
  }
  
  // MARK: cell
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
    let reusableCell = tableView.dequeueReusableCellWithIdentifier(reusableCellIdentifier, forIndexPath: indexPath)
    
    return reusableCell
    
  }
  
  // MARK: edit
  override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    return true
  }
  
  override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    
    guard let object = fetchedResultsController.objectAtIndexPath(indexPath) as? NSManagedObject
      where editingStyle == .Delete
      else { return }
    
    managedObjectContext.deleteObject(object)
    
  }

}

extension UITableViewControllerWithFetchedResultsController: NSFetchedResultsControllerDelegate  {
  
  var fetchedResultsController: NSFetchedResultsController {
    if _fetchedResultsController != nil {
      return _fetchedResultsController!
    }
    
    // Edit the entity name as appropriate.
    let entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: managedObjectContext)
    
    let fetchRequest = NSFetchRequest()
    fetchRequest.entity = entity
    
    // Set the batch size to a suitable number.
    fetchRequest.fetchBatchSize = 20
    
    fetchRequest.sortDescriptors = sortDescriptors
    
    fetchRequest.predicate = predicate
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: cacheName)
    aFetchedResultsController.delegate = self
    _fetchedResultsController = aFetchedResultsController
    
    reFetchResults(false)
    
    return aFetchedResultsController
    
  }
  
  func clearCache() {
    if let cacheName = cacheName {
      NSFetchedResultsController.deleteCacheWithName(cacheName)
    }
  }
  
  func reloadFetchedResultsControllerData(clearCache: Bool = true, reloadData: Bool = true) {
    if clearCache {
      self.clearCache()
    }
    reFetchResults(reloadData)
  }
  
  private func reFetchResults(reloadData: Bool = true) {
    
    do {
      try _fetchedResultsController!.performFetch()
      if reloadData {
        tableView.reloadData()
      }
    } catch {
      // Replace this implementation with code to handle the error appropriately.
      // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
      print("Unresolved error \(error)")
      //abort()
    }
  }
  
  func controllerWillChangeContent(controller: NSFetchedResultsController) {
    tableView.beginUpdates()
  }
  
  func controller(
    controller: NSFetchedResultsController,
    didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
    atIndex sectionIndex: Int,
    forChangeType type: NSFetchedResultsChangeType)
  {
    switch type {
    case .Insert:
      tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
    case .Delete:
      tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
    default:
      return
    }
  }
  
  func controller(
    controller: NSFetchedResultsController,
    didChangeObject anObject: AnyObject,
    atIndexPath indexPath: NSIndexPath?,
    forChangeType type: NSFetchedResultsChangeType,
    newIndexPath: NSIndexPath?)
  {
    switch type {
    case .Insert:
      tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
    case .Delete:
      tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
    case .Update:
      if #available(iOS 9, *) {
        tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
      } else {
        tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .None)
        tableView.insertRowsAtIndexPaths([indexPath!], withRowAnimation: .None)
      }
    case .Move:
      tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
      tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
    }
  }
  
  func controllerDidChangeContent(controller: NSFetchedResultsController) {
    self.tableView.endUpdates()
  }
  
}
