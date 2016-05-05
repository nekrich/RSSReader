//
//  RawRSSFeedFactory.swift
//  RSSReader
//
//  Created by Vitalii Budnik on 5/5/16.
//  Copyright © 2016 org. All rights reserved.
//

import Foundation

class RawRSSFeedFactory: NSObject {
  
  static func parserForURL(url: NSURL) -> RSSXMLParser.Type {
    guard let hostComponents = url.host?.lowercaseString.componentsSeparatedByString(".") else {
      return RSSXMLParser.self
    }
    
    let hostComponentsCount = hostComponents.count
    if hostComponentsCount < 2 {
      return RSSXMLParser.self
    }
    
    let domainName2Components = hostComponents[hostComponentsCount-2...hostComponentsCount-1].joinWithSeparator(".")
    if domainName2Components == "apple.com" {
      return AppleRSSXMLParser.self
    }
    
    return RSSXMLParser.self
    
  }
  
  static func parseURLToRSSFeed(
    url: NSURL,
    completionHandler completion: ((RawRSSFeed?) -> Void)? = .None)
  {
    let parser = RawRSSFeedFactory(parserType: parserForURL(url))
    parser.parseURLToRSSFeed(url, completionHandler: completion)
  }
  
  let Parser: RSSXMLParser.Type
  
  private init(parserType: RSSXMLParser.Type) {
    Parser = parserType
    super.init()
  }
  
  private func parseURLToRSSFeed(
    url: NSURL,
    completionHandler completion: ((RawRSSFeed?) -> Void)? = .None)
  {
    
    NSURLSession.sharedSession()
      .dataTaskWithURL(url) { (data, response, error) in
        
        if let error = error {
          debugPrint(error)
          completion?(.None)
          return
        }
        
        self.parseData(data, fromURL: url, completionHandler: completion)
        
      }.resume()
    
  }
  
  private func parseData(
    data: NSData?,
    fromURL url: NSURL,
    completionHandler completion: ((RawRSSFeed?) -> Void)? = .None)
  {
    
    guard let data = data else {
      completion?(.None)
      return
    }
    
    let parser = Parser.init(data: data, fromURL: url)
    
    //let dataString = String(data: data, encoding: NSUTF8StringEncoding)
    
    completion?(parser.parse())
    
  }
  
}
