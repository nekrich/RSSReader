//
//  RSSFeed+Parser.swift
//  RSSReader
//
//  Created by Vitalii Budnik on 5/5/16.
//  Copyright © 2016 org. All rights reserved.
//

import Foundation
import CoreData

extension RSSFeed {
  
  func fetchNews(comletionHandler: ((RSSFeed?) -> Void)? = .None) {
    guard let
      urlString = urlString,
      url = NSURL(string: urlString),
      moc = managedObjectContext
      else { return }
    
    let completion: (RSSFeed?) -> Void = { rssFeed in
      guard let comletionHandler = comletionHandler else { return }
      dispatch_async(dispatch_get_main_queue()) {
        comletionHandler(rssFeed)
      }
    }
    
    RawRSSFeedFactory.parseURLToRSSFeed(url) { (rawFeed) in
      
      guard let rawFeed = rawFeed else { completion(self); return }
      
      moc.performBlock {
        self.fillWithRawRSSFeedData(rawFeed)
        completion(self)
      }
      
    }
    
  }
  
  
  private func fillWithRawRSSFeedData(rawRSSFeed: RawRSSFeed) {
    
    guard let moc = managedObjectContext else { return }
    
    self.title = rawRSSFeed.title
    self.urlString = rawRSSFeed.url.absoluteString
    
    var fetchedItemsIDs: [NSManagedObjectID] = []
    rawRSSFeed.items.forEach { (item) in
      
      guard let rssItem = RSSItem.addItem(item, toFeed: self) else { return }
      
      fetchedItemsIDs.append(rssItem.objectID)
      
    }
    
    // deleting old marked for deletion items
    
    let deleteItemsRequest = NSFetchRequest(entityName: "RSSItem")
    deleteItemsRequest.predicate = NSPredicate(
      format: "feed = %@ && deletionMark == TRUE && !(self IN %@)",
      self,
      fetchedItemsIDs)
    
    if let
      fetchResult = try? moc.executeFetchRequest(deleteItemsRequest) as? [NSManagedObject],
      fetchedObjects = fetchResult
      where !fetchedObjects.isEmpty
    {
      fetchedObjects.forEach {
        moc.deleteObject($0)
      }
    }
    
    do {
      try moc.save()
    } catch {
      print(error)
    }
    
  }
  /**
   Adds new feed from URL
   
   - parameter url: URL of new feed
   - parameter completion: Closure, that takes a newly created `RSSFeed?` as a parameter.
   `nil` if some error occurred
   */
  class func addNewFeedFromURL(url: NSURL, comletionHandler: ((RSSFeed?) -> Void)? = .None) {
    
    let completion: (RSSFeed?) -> Void = { rssFeed in
      guard let comletionHandler = comletionHandler else { return }
      dispatch_async(dispatch_get_main_queue()) {
        comletionHandler(rssFeed)
      }
    }
    
    RawRSSFeedFactory.parseURLToRSSFeed(url) { (rawFeed) in
      
      guard let rawFeed = rawFeed else {
        completion(.None)
        return
      }
      
      var result: RSSFeed? = .None
      
      let moc = CoreDataHelper.newManagedObjectContext()
      
      moc.performBlockAndWait {
        
        let fetchRequest = NSFetchRequest(entityName: "RSSFeed")
        fetchRequest.predicate = NSPredicate(format: "urlString == %@", rawFeed.url.absoluteString)
        fetchRequest.fetchLimit = 1
        
        let managedObject: NSManagedObject
        if let
          fetchResult = try? moc.executeFetchRequest(fetchRequest) as? [NSManagedObject],
          fetchedObjects = fetchResult
          where fetchedObjects.count > 0
        {
          managedObject = fetchedObjects[0]
        } else {
          managedObject = NSEntityDescription.insertNewObjectForEntityForName(
            "RSSFeed",
            inManagedObjectContext: moc)
        }
        
        guard let newFeed = managedObject as? RSSFeed else {
          moc.undo()
          completion(.None)
          return
        }
        
        newFeed.fillWithRawRSSFeedData(rawFeed)
        
        result = newFeed
        
      }
      
      completion(result)
      
    }
    
  }
  
}
