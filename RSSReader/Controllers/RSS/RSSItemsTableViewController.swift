//
//  RSSItemsTableViewController.swift
//  RSSReader
//
//  Created by Vitalii Budnik on 5/5/16.
//  Copyright © 2016 org. All rights reserved.
//

import Foundation
import UIKit
import SafariServices

class RSSItemsTableViewController: UITableViewControllerWithFetchedResultsController {
  
  var rssFeed: RSSFeed? = .None {
    didSet {
      title = rssFeed?.title
      updatePredicate()
    }
  }
  
  var fetchNewsTimer: NSTimer? = .None
  
  var newsUpdateInterval: NSTimeInterval = 3.0 * 60.0 {
    didSet {
      fetchNewsTimer?.fire()
      startTimer()
    }
  }
  
  var dateFormatter: NSDateFormatter = {
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateStyle = .ShortStyle
    dateFormatter.timeStyle = .ShortStyle
    return dateFormatter
  }()
  
  /// `UIApplicationDidEnterBackgroundNotification` notification observer
  private var applicationDidEnterBackgroundObserver: NSObjectProtocol? = .None
  
  /// `UIApplicationDidBecomeActiveNotification` notification observer
  private var applicationDidBecomeActiveObserver: NSObjectProtocol? = .None
  
  // MARK: - Lifecycle
  override func viewDidLoad() {
    updateSortDescriptors()
    super.viewDidLoad()
    addApplicationStateChangeObservers()
    
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.estimatedRowHeight = UITableViewAutomaticDimension
    
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
    startTimer()
    fetchNewsTimer?.fire()
    
  }
  
  deinit {
    removeApplicationStateChangeObservers()
  }
  
  // MARK: - UI
  
  @IBAction func refreshRSSFeed() {
    stopTimer() // no autoupdates when fetching manually
    
    fetchNews() { [weak self] in
      
      guard let sSelf = self else { return }
      
      sSelf.refreshControl?.endRefreshing()
      
      sSelf.startTimer() // start autoupdates
      
    }
    
  }
  
  // MARK: - Mark as read
  /**
   Marks `RSSItem` for selected row in `tableView` as read
   */
  func markSelectedRSSItmesRead() {
    
    guard let
      indexPath = tableView.indexPathForSelectedRow,
      rssItem = fetchedResultsController.objectAtIndexPath(indexPath) as? RSSItem
      where !rssItem.read
      else {
        return
    }
    
    rssItem.read = true
    
  }
  
  
  
  
}

// MARK: - UITableViewDelegate
extension RSSItemsTableViewController {
  
  override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return UITableViewAutomaticDimension
  }
  
  override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return UITableViewAutomaticDimension
  }
  
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    guard let
      rssItem = fetchedResultsController.objectAtIndexPath(indexPath) as? RSSItem,
      urlString = rssItem.urlString,
      url = NSURL(string: urlString)
      else { return }
    if #available(iOS 9, *) {
      let safariController = SFSafariViewController(URL: url)
      safariController.delegate = self
      presentViewController(safariController, animated: true, completion: .None)
    } else {
      let webViewController = WebViewController(urlRequest: NSURLRequest(URL: url))
      webViewController.title = rssItem.title
      webViewController.delegate = self
      navigationController?.pushViewController(webViewController, animated: true)
    }
    
  }
  
}

// MARK: - UITableViewDataSource
extension RSSItemsTableViewController {
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
    let cell = tableView.dequeueReusableCellWithIdentifier(reusableCellIdentifier, forIndexPath: indexPath)
    
    guard let rssItemCell = cell as? RSSItemCell else { return cell }
    
    let rssItem = (fetchedResultsController.objectAtIndexPath(indexPath) as! RSSItem)
    
//    rssItemCell.textLabel?.text = object.title
//    rssItemCell.detailTextLabel?.text = object.itemDescription
    
    rssItemCell.configureWithRSSItem(rssItem)
    
    return rssItemCell
    
  }
  
  override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    
    guard let object = fetchedResultsController.objectAtIndexPath(indexPath) as? RSSItem
      where editingStyle == .Delete
      else { return }
    
    object.deletionMark = true
    
  }
  
}

// MARK: - News fetching
extension RSSItemsTableViewController {
  
  func fetchNews(completionHandler: (() -> Void)? = .None) {
    guard let
      rssFeed = rssFeed
      else { return }
    
    rssFeed.fetchNews() { [weak self] _ in
      guard let sSelf = self else { completionHandler?(); return }
      
      sSelf.refreshControl?.attributedTitle = NSAttributedString(
        string: "Last refreshed: " + sSelf.dateFormatter.stringFromDate(NSDate()),
        attributes: .None)
      
      sSelf.refreshControl?.endRefreshing()
      
      completionHandler?()
    }
    
  }
  
}

// MARK: - Application state observing
extension RSSItemsTableViewController {
  
  func addApplicationStateChangeObservers() {
    
    applicationDidEnterBackgroundObserver = NSNotificationCenter.defaultCenter().addObserverForName(
      UIApplicationDidEnterBackgroundNotification,
      object: .None,
      queue: .None) { [weak self] _ in
        self?.stopTimer()
    }
    
    applicationDidBecomeActiveObserver = NSNotificationCenter.defaultCenter().addObserverForName(
      UIApplicationDidBecomeActiveNotification,
      object: .None,
      queue: .None) { [weak self] _ in
        self?.startTimer()
        self?.fetchNewsTimer?.fire()
    }
    
  }
  
  func removeApplicationStateChangeObservers() {
    
    if let applicationDidEnterBackgroundObserver = applicationDidEnterBackgroundObserver {
      NSNotificationCenter.defaultCenter().removeObserver(
        applicationDidEnterBackgroundObserver,
        name: UIApplicationDidEnterBackgroundNotification,
        object: .None)
      self.applicationDidEnterBackgroundObserver = .None
    }
    
    if let applicationDidBecomeActiveObserver = applicationDidBecomeActiveObserver {
      NSNotificationCenter.defaultCenter().removeObserver(
        applicationDidBecomeActiveObserver,
        name: UIApplicationDidBecomeActiveNotification,
        object: .None)
      self.applicationDidBecomeActiveObserver = .None
    }
    
  }
  
}

// MARK: - Timer
extension RSSItemsTableViewController {
  
  /// Starts auto-fetch RSS feed
  func startTimer() {
    stopTimer()
    if UIApplication.sharedApplication().applicationState == .Active {
      fetchNewsTimer = NSTimer.scheduledTimerWithTimeInterval(
        newsUpdateInterval,
        target: self,
        selector: #selector(fetchNewsTimerFired(_:)),
        userInfo: .None,
        repeats: true)
    }
  }
  
  /// Stops auto-fetch RSS feed
  func stopTimer() {
    fetchNewsTimer?.invalidate()
    fetchNewsTimer = .None
  }
  
  /**
   Wrapper for `fetchNewsTimer selector`
   
   - parameter sender: fired `NSTimer`
   */
  @objc func fetchNewsTimerFired(sender: NSTimer) {
    fetchNews()
  }
  
}

// MARK: - Sort
extension RSSItemsTableViewController {
  
  func updatePredicate() {
    let feedPredicate: NSPredicate?
    if let rssFeed = rssFeed {
      feedPredicate = NSPredicate(format: "feed == %@", rssFeed)
    } else {
      feedPredicate = .None
    }
    
    let deletionMarkPredicate = NSPredicate(format: "deletionMark == false", argumentArray: .None)
    
    predicate = NSCompoundPredicate(
      andPredicateWithSubpredicates: [deletionMarkPredicate, feedPredicate].flatMap { $0 })
    
  }
  
  func updateSortDescriptors() {
    sortDescriptors = [
      NSSortDescriptor(key: "publishDate", ascending: false)
    ]
  }
  
}

// MARK: - SFSafariViewControllerDelegate
extension RSSItemsTableViewController: SFSafariViewControllerDelegate {
  
  @available(iOS 9.0, *)
  func safariViewControllerDidFinish(controller: SFSafariViewController) {
    markSelectedRSSItmesRead()
  }
  
}

// MARK: - WebViewControllerDelegate
extension RSSItemsTableViewController: WebViewControllerDelegate {
  
  func webViewControllerWillDisappear(webViewController: WebViewController) {
    markSelectedRSSItmesRead()
  }
  
}
