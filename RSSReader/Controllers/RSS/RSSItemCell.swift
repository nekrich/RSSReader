//
//  RSSItemCell.swift
//  RSSReader
//
//  Created by Vitalii Budnik on 5/5/16.
//  Copyright © 2016 org. All rights reserved.
//

import Foundation
import UIKit

class RSSItemCell: UITableViewCell {
  
  
  @IBOutlet var itemTitleLabel: UILabel!
  @IBOutlet var itemDescriptionLabel: UILabel!
  
  func configureWithRSSItem(rssItem: RSSItem) {
    
    itemTitleLabel.text = rssItem.title
    itemDescriptionLabel.text = rssItem.itemDescription
    
    let labelTextColor: UIColor
    if rssItem.read {
      labelTextColor = UIColor.darkGrayColor()
    } else {
      labelTextColor = UIColor.blackColor()
    }
    
    itemTitleLabel.textColor = labelTextColor
    itemDescriptionLabel.textColor = labelTextColor
   
  }
  
}