//
//  WebViewController.swift
//  RSSReader
//
//  Created by Vitalii Budnik on 5/5/16.
//  Copyright © 2016 org. All rights reserved.
//

import Foundation
import UIKit
import WebKit

private let kEstimatedProgressKeyPath = "estimatedProgress"

protocol WebViewControllerDelegate: class {
  func webViewControllerWillDisappear(webViewController: WebViewController)
}

class WebViewController: UIViewController {
  
  private lazy var _webView: WKWebView = { [unowned self] in
    
    let webView = WKWebView(frame: CGRect.zero, configuration: self.configuration)
    
    self.view.insertSubview(webView, belowSubview: self.progressBar)
    
    webView.addObserver(self, forKeyPath: kEstimatedProgressKeyPath, options: .New, context: nil)
    
    webView.allowsBackForwardNavigationGestures = false
    
    return webView
    }()
  
  var webView: WKWebView {
    return _webView
  }
  
  lazy final var _progressBar: UIProgressView = { [unowned self] in
    let progressBar = UIProgressView(progressViewStyle: .Bar)
    progressBar.backgroundColor = .clearColor()
    progressBar.trackTintColor = .clearColor()
    self.view.addSubview(progressBar)
    return progressBar
    }()
  
  var progressBar: UIProgressView {
    return _progressBar
  }
  
  private let configuration: WKWebViewConfiguration
  
  var urlRequest: NSURLRequest? = .None {
    didSet {
      webView.stopLoading()
      guard let urlRequest = urlRequest else {
        return
      }
      webView.loadRequest(urlRequest)
    }
  }
  
  weak var delegate: WebViewControllerDelegate? = .None
  
  init(urlRequest: NSURLRequest, configuration: WKWebViewConfiguration = WKWebViewConfiguration()) {
    
    self.configuration = configuration
    self.urlRequest = urlRequest
    
    super.init(nibName: nil, bundle: nil)
    
  }
  
  required init?(coder aDecoder: NSCoder) {
    
    self.configuration = WKWebViewConfiguration()
    
    super.init(coder: aDecoder)
    
  }

  deinit {
    webView.removeObserver(self, forKeyPath: kEstimatedProgressKeyPath)
  }
  
}

// MARK: View lifecycle
extension WebViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if let request = urlRequest where !webView.loading {
      webView.loadRequest(request)
    }
    
  }
  
  override func viewWillDisappear(animated: Bool) {
    delegate?.webViewControllerWillDisappear(self)
    webView.stopLoading()
    super.viewWillDisappear(animated)
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    webView.frame = view.bounds
    
    let insets = UIEdgeInsets(top: topLayoutGuide.length, left: 0, bottom: 0, right: 0)
    webView.scrollView.contentInset = insets
    webView.scrollView.scrollIndicatorInsets = insets
    
    progressBar.frame = CGRect(
      x: view.frame.minX,
      y: topLayoutGuide.length,
      width: view.frame.size.width,
      height: 2)
  }
  
}

// MARK: KVO
extension WebViewController {
  
  override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
    guard let theKeyPath = keyPath
      where object as? WKWebView == webView
        && theKeyPath == kEstimatedProgressKeyPath
      else {
        super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        return
    }
    
    if theKeyPath == kEstimatedProgressKeyPath {
      updateProgress()
    }
    
  }
  
  private func updateProgress() {
    let completed = webView.estimatedProgress == 1.0
    progressBar.setProgress(completed ? 0.0 : Float(webView.estimatedProgress), animated: !completed)
  }
  
}
