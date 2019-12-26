//
//  ViewController.swift
//  WebBrowser
//
//  Created by khoa on 12/18/19.
//  Copyright © 2019 khoa. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController, UISearchBarDelegate, UIWebViewDelegate, WKNavigationDelegate, WKUIDelegate {
    
    @IBOutlet weak var mySearchBar: UISearchBar!
    @IBOutlet weak var myWebView: WKWebView!
    @IBOutlet weak var myProgressView: UIProgressView!
    
    @IBAction func back(_ sender: Any) {
        if myWebView.canGoBack{
            myWebView.goBack()
        }
    }
    
    @IBAction func refresh(_ sender: Any) {
        myWebView.reload()
    }
    
    
    @IBAction func next(_ sender: Any) {
        if myWebView.canGoForward {
            myWebView.goForward()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        mySearchBar.resignFirstResponder()
        
        if let url = URL(string: mySearchBar.text!){
            myWebView.load(URLRequest(url: url))
        } else {
            print("Error")
        }
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        mySearchBar.text = myWebView.url?.absoluteString
        myProgressView.setProgress(0.0, animated: false)
        
        let docsPath = Bundle.main.resourcePath!
        let fileManager = FileManager.default
        
        do {
            let docsArray = try  fileManager.contentsOfDirectory(atPath: docsPath)
            print(docsArray)
        } catch {
            print(error)
            
        }
        
    }
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            myProgressView.isHidden = myWebView.estimatedProgress == 1
            myProgressView.progress = (Float(myWebView.estimatedProgress))
        }
    }
    
    func initWebView(configuration: WKWebViewConfiguration)
    {
        let webView = WKWebView(frame: UIScreen.main.bounds, configuration: configuration)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        view.addSubview(webView)
        self.myWebView = webView
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        var wv: WKWebView?
        debugPrint("Hello world")
        if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "ViewController")  as? ViewController {
            viewController.initWebView(configuration: configuration)
            self.navigationController?.pushViewController(viewController, animated: true)
            
            wv = viewController.myWebView
            present(viewController, animated: true, completion: nil)
            viewController.removeFromParent()
        }
        return wv
    }
    
    func loadBlockRules() -> String?{
        guard let blockerFile = Bundle.main.path(forResource: "blockerList", ofType: "json") else {
            return nil
        }
        
        do { // Extract the file contents, and return them as a split string array
            let blockRules = try String(contentsOfFile: blockerFile)
            return blockRules
        } catch {
            debugPrint("Can not load file")
            return nil
        }
    }
    
    func compileRuleList() {
        let blockRules = loadBlockRules()
        
        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: "ContentBlockingRules",
            encodedContentRuleList: blockRules) { (contentRuleList, error) in
                
                if let error = error {
                    debugPrint(#function, error)
                    return
                }
                
                let configuration = self.myWebView.configuration
                configuration.userContentController.add(contentRuleList!)
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        compileRuleList()
        
        if myWebView == nil { initWebView(configuration: WKWebViewConfiguration()) }
        myWebView.navigationDelegate = self
        myWebView.uiDelegate = self
        myWebView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        myWebView.load(URLRequest(url: URL(string: "https://vnexpress.net")!))
    }
}
