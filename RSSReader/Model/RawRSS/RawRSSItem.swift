//
//  RawRSSItem.swift
//  RSSReader
//
//  Created by Vitalii Budnik on 5/5/16.
//  Copyright © 2016 org. All rights reserved.
//

import Foundation

struct RawRSSItem {
  
  let guid: String
  let title: String?
  let itemDescription: String?
  let link: String
  let publishDateString: String
  
  /**
   RSS item publish date
   - Warning: Time interval from 00:00:00 UTC on 1 January 2001.
   
   Use `timeIntervalSinceReferenceDate` methods/properties of `NSDate` objects if needed.
   */
  var publishTimeInterval: NSTimeInterval
  
  init?(rssItemDictionary: [String: String], dateFormatter: NSDateFormatter) {
    
    guard let
      guid = rssItemDictionary["guid"] ?? rssItemDictionary["link"],
      link = rssItemDictionary["link"],
      publishDateString = rssItemDictionary["pubDate"],
      publishTimeInterval = dateFormatter.dateFromString(publishDateString)?.timeIntervalSinceReferenceDate
      else { return nil }
    
    self.guid                = guid
    self.link                = link
    self.publishDateString   = publishDateString
    self.publishTimeInterval = publishTimeInterval
    
    title           = rssItemDictionary["title"]
    itemDescription = rssItemDictionary["description"]
    
  }
  
}
