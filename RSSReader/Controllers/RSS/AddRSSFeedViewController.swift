//
//  AddRSSFeedViewController.swift
//  RSSReader
//
//  Created by Vitalii Budnik on 5/4/16.
//  Copyright © 2016 org. All rights reserved.
//

import Foundation
import UIKit
import CoreData

extension UIAlertController {
  
  class func errorAlert(text: String, cancelActionHandler: (() -> Void)?) -> UIAlertController {
    let alert = UIAlertController(title: "Error", message: text, preferredStyle: .Alert)
    alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler:  { _ in cancelActionHandler?() }))
    return alert
  }
  
}

extension UIViewController {
  
  func showError(text: String, cancelActionHandler: (() -> Void)?) {
    presentViewController(
      UIAlertController.errorAlert(
        text,
        cancelActionHandler: cancelActionHandler),
      animated: true,
      completion: .None)
  }
  
  func showErrorAndDissmiss(text: String) {
    presentViewController(
      UIAlertController.errorAlert(
        text,
        cancelActionHandler: { [weak self] in
          if let popoverPresentationController = self?.popoverPresentationController {
            popoverPresentationController.delegate?.popoverPresentationControllerDidDismissPopover?(popoverPresentationController)
          }
          self?.dismissViewControllerAnimated(true, completion: .None)
      }),
      animated: true,
      completion: .None)
  }
  
  func dismissViewController() {
    
    if let popoverPresentationController = popoverPresentationController {
      popoverPresentationController.delegate?.popoverPresentationControllerDidDismissPopover?(popoverPresentationController)
    }
    dismissViewControllerAnimated(true, completion: .None)
    
  }
  
}

class AddRSSFeedViewController: UIViewController {
  
  @IBOutlet var urlLabel: UILabel!
  @IBOutlet var feedURLtextField: UITextField!
  
  @IBOutlet var toolbar: UIToolbar!
  
  @IBOutlet var activityIndicator: UIActivityIndicatorView!
  
  @IBAction func saveBarButtonPressed(sender: UIBarButtonItem) {
    
    feedURLtextField.resignFirstResponder()
    
    guard let feedURLString = feedURLtextField.text where !feedURLString.isEmpty else {
      showErrorAndDissmiss("Empty URL")
      return
    }
    
    guard let url = NSURL(string: feedURLString) else {
      showErrorAndDissmiss("Wrong URL")
      return
    }
    
    let presentingViewController = self.presentingViewController
    RSSFeed.addNewFeedFromURL(url) { [weak self, weak presentingViewController] feed in
      guard let sSelf = self ?? presentingViewController else { return }
      
      guard let _ = feed else {
        sSelf.showErrorAndDissmiss("Can't parse Feed")
        return
      }
      
      sSelf.dismissViewController()
      
    }
    
    dismissViewController()
    
  }
  
  @IBAction func cancelBarButtonPressed(sender: UIBarButtonItem) {
    feedURLtextField.resignFirstResponder()
    dismissViewController()
  }
  
  override func viewWillDisappear(animated: Bool) {
    if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
      UIApplication.sharedApplication().endIgnoringInteractionEvents()
    }
  }
  
  func startAnimatingActivityIndicator() {
    UIApplication.sharedApplication().beginIgnoringInteractionEvents()
    UIView.animateWithDuration(0.3) {
      self.activityIndicator.startAnimating()
      self.toolbar.hidden = true
      self.urlLabel.hidden = true
      self.feedURLtextField.hidden = true
    }
    
  }
  
}