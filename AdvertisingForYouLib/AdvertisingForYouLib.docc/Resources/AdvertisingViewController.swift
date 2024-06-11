//
//  AdvertisingViewController.swift
//  
//
//  Created by Nikita Stepanov on 11.06.2024.
//

import UIKit
import WebKit
import Network

public class AdViewController: UIViewController {
    
    // MARK: - Properties
    private var adWebView: WKWebView!
    
    public let netAlert = UIAlertController(title: "Connection problems :(",
                                            message: "To continue, you should be online",
                                            preferredStyle: .alert)
    
    private var topConstraint: NSLayoutConstraint?
    
    private var adUrl: URL
    
    private func configWebView() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptEnabled = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        return configuration
    }

    public init(adUrl: URL) {
        self.adUrl = adUrl
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public var prefersStatusBarHidden: Bool {
        return true
    }
    
    private func setUp() {
        view.backgroundColor = .black
        adWebView = WKWebView(frame: view.bounds, configuration: configWebView())
        adWebView.translatesAutoresizingMaskIntoConstraints = false
        adWebView.navigationDelegate = self
        view.addSubview(adWebView)
        
        NSLayoutConstraint.activate([
            adWebView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            adWebView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            adWebView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        topConstraint = adWebView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0)
        topConstraint!.isActive = true
        
        let request = URLRequest(url: adUrl)
        adWebView.load(request)
    }
    func showNetPopUp() {
        present(netAlert, animated: true, completion: nil)
    }
    
    func hideNetPopUp() {
        netAlert.dismiss(animated: true)
    }
    
    func checkInternetConnection() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                DispatchQueue.main.async {
                    self.hideNetPopUp()
                }
            } else {
                DispatchQueue.main.async {
                    self.showNetPopUp()
                }
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
    
    override public func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        super.didRotate(from: fromInterfaceOrientation)
        topConstraint?.constant = self.view.frame.size.height > self.view.frame.size.width ? 70 : 0
        view.updateConstraintsIfNeeded()
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setUp()
        checkInternetConnection()
    }
}

extension AdWebViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("WebView finished loading")
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("WebView loading failed: \(error.localizedDescription)")
    }
}

