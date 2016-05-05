//
//  RawRSSFeed.swift
//  RSSReader
//
//  Created by Vitalii Budnik on 5/5/16.
//  Copyright © 2016 org. All rights reserved.
//

import Foundation

struct RawRSSFeed {
  let title: String?
  let description: String?
  let url: NSURL
  let items: [RawRSSItem]
}
