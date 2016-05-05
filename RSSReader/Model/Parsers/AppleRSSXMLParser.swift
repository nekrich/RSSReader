//
//  AppleRSSXMLParser.swift
//  RSSReader
//
//  Created by Vitalii Budnik on 5/5/16.
//  Copyright © 2016 org. All rights reserved.
//

import Foundation

class AppleRSSXMLParser: RSSXMLParser {
  
  required init(data: NSData, fromURL url: NSURL) {
    super.init(data: data, fromURL: url)
    dateFormatterDateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
  }
  
}