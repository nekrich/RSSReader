//
//  AppDelegate.swift
//  RSSReader
//
//  Created by Vitalii Budnik on 5/4/16.
//  Copyright © 2016 org. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {
  
  var window: UIWindow?
  
  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    // Override point for customization after application launch.
    let splitViewController = self.window!.rootViewController as! UISplitViewController
    let detailNavigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
    detailNavigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem()
    splitViewController.delegate = self
    
    let masterNavigationController = splitViewController.viewControllers[0] as! UINavigationController
    let masterController = masterNavigationController.topViewController! as! RSSFeedsTableViewController
    
    if let rssFeeds = masterController.fetchedResultsController.fetchedObjects as? [RSSFeed] {
      rssFeeds.forEach {
        $0.fetchNews()
      }
    }
    
    return true
    
  }
  
  // MARK: - Split view
  func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController:UIViewController, ontoPrimaryViewController primaryViewController:UIViewController) -> Bool {
      guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
      guard let topAsRSSItemsController = secondaryAsNavController.topViewController as? RSSItemsTableViewController else { return false }
      if topAsRSSItemsController.rssFeed == nil {
          // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
          return true
      }
      return false
  }
  
}

