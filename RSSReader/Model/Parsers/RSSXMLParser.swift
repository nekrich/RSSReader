//
//  RSSXMLParser.swift
//  RSSReader
//
//  Created by Vitalii Budnik on 5/4/16.
//  Copyright © 2016 org. All rights reserved.
//

import Foundation

class RSSXMLParser: NSObject {
  
  /// Parse current element
  private var parseCurrentElement = false
  
  /// Found first item entrance
  private var parsingItems = false

  /// Elemet starting tag
  private let itemsStartsFromElement = ["item"]

  ///  current parsing element
  private var currentElement = ""

  private var foundCharactersInElemet = ""
  
  private var feedTitle: String? = .None
  private var feedDescription: String? = .None

  private var currentItemDictionary = [String: String]()
  
  private let elementesToParse = ["title", "description", "link", "guid", "pubDate", "id", "updated", "summary", "content", "author", "enclosure"]

  private var rssItems = [[String: String]]()

  private let url: NSURL
  
  private let data: NSData
  
  var dateFormatterDateFormat = "EEE, dd MMM yyyy HH:mm:ss ZZZ"
  
  required init(data: NSData, fromURL url: NSURL) {
    
    self.url = url
    self.data = data
    super.init()
    
  }
  
  deinit {
    objc_removeAssociatedObjects(self)
  }
  
}

// MARK: Parsing
extension RSSXMLParser {
  
  private struct AssociatedKeys {
    static var dateFormatter = 0
  }
  
  /**
   `NSDateFormatter`, used to convert string `pubDate` field from RSS item
   
   - returns: `NSDateFormatter`
   */
  func dateFormatter() -> NSDateFormatter {
    if let
      dateFormatter = objc_getAssociatedObject(
        self,
        &AssociatedKeys.dateFormatter) as? NSDateFormatter
    {
      return dateFormatter
    }
    
    let dateFormatter = NSDateFormatter()
    dateFormatter.locale = NSLocale(localeIdentifier: "en")
    dateFormatter.dateFormat = dateFormatterDateFormat
    // Income:				    Tue, 10 Nov 2015 18:10:09 +0000
    /*
     http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Field_Symbol_Table
     */
    
    objc_setAssociatedObject(
      self,
      &AssociatedKeys.dateFormatter,
      dateFormatter,
      .OBJC_ASSOCIATION_RETAIN)
    
    return dateFormatter
    
  }
  
  /**
   Starts the event-driven parsing operation.
   
   Returns `RawRSSFeed` if parsing is successful and `nil` in there is an error
   or if the parsing operationn is aborted.
   
   - returns: `RawRSSFeed` if parsing is successful and `nil` in there is an error 
   or if the parsing operationn is aborted.
   
   */
  func parse() -> RawRSSFeed? {
    
    let parser = NSXMLParser(data: data)
    parser.delegate = self
    
    guard parser.parse() else { clear(); return .None }
    
    let rssFeed = RawRSSFeed(
      title: feedTitle,
      description: feedDescription,
      url: url,
      items: rssItems.flatMap { getRawRSSItemFromRSSItemDictionary($0) } )
    
    clear()
    
    return rssFeed
    
  }
  
  /**
   Converts passed `rssItemDictionary` to `RawRSSItem`
   
   - parameter rssItemDictionary: `[String: String]` - parsed RSS item data
   
   - returns: `RawRSSItem` if conversion is successful, `nil` otherwise
   */
  func getRawRSSItemFromRSSItemDictionary(rssItemDictionary: [String: String]) -> RawRSSItem? {
    return RawRSSItem(
      rssItemDictionary: rssItemDictionary,
      dateFormatter: dateFormatter())
  }
  
  /**
   Clear cache variables `rssItems, feedTitle, feedDescription`
   */
  private func clear() {
    rssItems = []
    feedTitle = .None
    feedDescription = .None
  }
  
}

// MARK: - NSXMLParserDelegate
extension RSSXMLParser: NSXMLParserDelegate {

  func parser(
    parser: NSXMLParser,
    didStartElement elementName: String,
    namespaceURI: String?,
    qualifiedName qName: String?,
    attributes attributeDict: [String : String])
  {
    currentElement = elementName
    
    if itemsStartsFromElement.contains(currentElement) {
      foundCharactersInElemet = ""
      parseCurrentElement = true
      parsingItems = true
    } else if elementName == "enclosure" {
      if let type = attributeDict["type"], url = attributeDict["url"] {
        if type.characters.count > 5 && type.substringToIndex(type.startIndex.advancedBy(6)) == "image/" {
          currentItemDictionary["imageURL"] = url
        }
      }
    } else if !parsingItems && (currentElement == "title" || currentElement == "description" ) {
      parseCurrentElement = true
    }
  }
  
  func parser(parser: NSXMLParser, foundCharacters string: String) {
    guard parseCurrentElement else { return }
    
    if elementesToParse.contains(currentElement) {
      foundCharactersInElemet += string
    }
  }
  
  func parser(
    parser: NSXMLParser,
    didEndElement elementName: String,
    namespaceURI: String?,
    qualifiedName qName: String?)
  {
    
    guard parseCurrentElement else { return }
    
    if itemsStartsFromElement.contains(elementName) {
      
      rssItems.append(currentItemDictionary)
      
      parseCurrentElement = false
      
      return
    }
    
    let foundCharacters = foundCharactersInElemet.stringByTrimmingCharactersInSet(
      NSCharacterSet.whitespaceAndNewlineCharacterSet())
    
    if foundCharacters.isEmpty { return }
    
    if parsingItems {
      currentItemDictionary[elementName] = foundCharacters
    } else {
      switch elementName {
      case "title":
        feedTitle = foundCharacters
        break
      case "description":
        feedDescription = foundCharacters
        break
      default:
        break
      }
    }
    
    foundCharactersInElemet = ""
    
  }
  
}
