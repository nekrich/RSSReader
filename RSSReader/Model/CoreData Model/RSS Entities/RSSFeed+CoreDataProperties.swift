//
//  RSSFeed+CoreDataProperties.swift
//  RSSReader
//
//  Created by Vitalii Budnik on 5/4/16.
//  Copyright © 2016 org. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension RSSFeed {

    @NSManaged var title: String?
    @NSManaged var urlString: String?
    @NSManaged var items: NSSet?

}
