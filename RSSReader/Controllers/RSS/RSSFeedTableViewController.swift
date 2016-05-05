//
//  RSSFeedTableViewController.swift
//  RSSReader
//
//  Created by Vitalii Budnik on 5/4/16.
//  Copyright © 2016 org. All rights reserved.
//

import Foundation
import UIKit
import CoreData

private let kFirstStart = "firstStart"

class RSSFeedsTableViewController: UITableViewControllerWithFetchedResultsController {
  
  // MARK: Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
    
    checkFirstStart()
    
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    
    let destinationViewController: UIViewController?
    
    if let navigationController = segue.destinationViewController as? UINavigationController {
      destinationViewController = navigationController.topViewController
    } else {
      destinationViewController = segue.destinationViewController
    }
    
    if let addRSSFeedController = destinationViewController as? AddRSSFeedViewController {
      prepareForSegueToAddRSSFeedController(addRSSFeedController)
      return
    }
    
    if let rssItemsController = destinationViewController as? RSSItemsTableViewController {
      prepareForSegueToRSSItemsTableViewController(rssItemsController, sender: sender)
      return
    }
    
  }
  
}

// MARK: - Segue
extension RSSFeedsTableViewController {
  
  func prepareForSegueToRSSItemsTableViewController(
    rssItemsController: RSSItemsTableViewController,
    sender: AnyObject?)
  {
    
    guard let cell = sender as? UITableViewCell else { return }
    
    guard let
      cellIndexPath = tableView.indexPathForCell(cell),
      rssFeed = fetchedResultsController.objectAtIndexPath(cellIndexPath) as? RSSFeed
      else { return }
    
    rssItemsController.rssFeed = rssFeed
    
  }
  
  func prepareForSegueToAddRSSFeedController(addRSSFeedController: AddRSSFeedViewController) {
    
    guard let
      popoverController = addRSSFeedController.popoverPresentationController
      else { return }
    
    popoverController.delegate = self
    
    // "Magic" numbers
    addRSSFeedController.preferredContentSize = CGSize(
      width: 280.0,
      height: 108.0)
    
  }
  
}
// MARK: - First start
extension RSSFeedsTableViewController {

  func checkFirstStart() {
    
    guard !NSUserDefaults.standardUserDefaults().boolForKey(kFirstStart) else { return }
    
    NSUserDefaults.standardUserDefaults().setBool(true, forKey: kFirstStart)
    
    addDefaultFeed()
    
  }
  
  func addDefaultFeed() {
    
    RSSFeed.addNewFeedFromURL(
      NSURL(string: "http://images.apple.com/main/rss/hotnews/hotnews.rss")!) { _ in
        CoreDataHelper.saveContext()
    }
    
  }
  
}

// MARK: - UIPopoverPresentationControllerDelegate
extension RSSFeedsTableViewController: UIPopoverPresentationControllerDelegate {
  
  func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
    return .None
  }
  
}

// MARK: - UITableViewDataSource
extension RSSFeedsTableViewController {
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
    let rssFeedCell = tableView.dequeueReusableCellWithIdentifier(reusableCellIdentifier, forIndexPath: indexPath)
    
    let object = (fetchedResultsController.objectAtIndexPath(indexPath) as! RSSFeed)
    
    rssFeedCell.textLabel?.text = object.title
    rssFeedCell.detailTextLabel?.text = object.urlString
    
    return rssFeedCell
  }
  
}