//
//  RSSItem+Parser.swift
//  RSSReader
//
//  Created by Vitalii Budnik on 5/5/16.
//  Copyright © 2016 org. All rights reserved.
//

import Foundation
import CoreData

extension RSSItem {
  
  private func fillWithRawRSSItem(rawRSSItem: RawRSSItem) {
    
    guid = rawRSSItem.guid
    
    urlString = rawRSSItem.link
    publishDate = rawRSSItem.publishTimeInterval
    
    itemDescription = rawRSSItem.itemDescription
    title = rawRSSItem.title
    
  }
  
  /**
   Returns `RSSItem` if sucessfully added to passed `feed`, `nil` otherwise
   
   - parameter rawRSSItem: raw rss item data data (`RawRSSItem`)
   - parameter feed: `RSSFeed`, that will contain newky created `RSSItem`
   
   - returns: `RSSItem` if sucessfully added to passed `feed`, `nil` otherwise
   */
  class func addItem(rawRSSItem: RawRSSItem, toFeed feed: RSSFeed) -> RSSItem? {
    
    guard let
      moc = feed.managedObjectContext
      else { return .None }
    
    if let rssItem = feed.items?
      .objectsPassingTest({ (item, _) in (item as! RSSItem).guid! == rawRSSItem.guid } ).first as? RSSItem
    {
      return rssItem
    }
    
    let newManagedObject = NSEntityDescription.insertNewObjectForEntityForName(
      "RSSItem",
      inManagedObjectContext: moc)
    
    guard let newItem = newManagedObject as? RSSItem else {
      moc.undo()
      return .None
    }
    
    newItem.feed = feed
    
    newItem.fillWithRawRSSItem(rawRSSItem)
    
    return newItem
  }
  
}