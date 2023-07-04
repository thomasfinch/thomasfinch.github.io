---
layout: post
title:  "Scraping Webpages on iOS"
date:   2015-08-10 12:00:00
categories: blog
---

A large component of an iOS app I'm currently working on involves scraping content from web pages. After some trial and error, I found a method that works well for me and wanted to share my choice and the reasoning behind it. While researching I found the following methods to be the most common:

* Load the page in an offscreen UIWebView and scrape it with JavaScript
* Parse the HTML with [NSXMLParser](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSXMLParser_Class/)
* Parse the HTML manually with regular expressions and string operations
* Third party libraries

I tried the first method, scraping with a UIWebView and JavaScript, and found that while it worked fine it was slow. The consensus online about NSXMLParser seemed to be that it's not a good choice for working with HTML, since NSXMLParser expects its input to be well-formed and it's unlikely that real world webpages always would be. I also briefly tried parsing the content I needed with regular expressions, but it didn't take much time before I was fed up with corner cases and gave it up. Finally, I didn't want to rely on third party libraries when I already had a working, although sub-optimal, solution with UIWebView.

Though it was slower, scraping through a web view meant that I didn't have to deal with parsing HTML myself and could take full advantage of the DOM for finding and manipulating elements. I decided to stay with the web view option, and focused on making it faster. My first thought was to try loading the page in a WKWebView instead of a UIWebView, but it didn't improve the speed noticeably. After putting print statements at various stages of the page load process I found that the slowest part of the process was after the page's body loaded but before the web view was completely done loading (i.e., it called the `webViewDidFinishLoad` delegate method). The initial loading of the page's HTML happened almost instantly, and the scraping JavaScript also took almost no time to run. However, the web view was still loading all of the page's content including images and other media, which drastically increased the page load time and the time it took before the page could be scraped. Since I was only interested in the page's HTML, all other content it loaded was just a waste of time, network usage, and potentially device battery life.

I ended up fixing this by simply stopping the web view from loading after the main document had finished loading since at that point it had all the content I was interested in. This would be tricky with a UIWebView, but fortunately WKWebView has great APIs for interacting with pages through JavaScript. [WKUserScript](https://developer.apple.com/library/mac/documentation/WebKit/Reference/WKUserScript_Ref/) allows injecting a script into a WKWebView at a specific time in the page load - in this case, `WKUserScriptInjectionTimeAtDocumentEnd`, "after the document has finished loading, but before any subresources may have finished loading". It also allows JavaScript within the web view to call native methods through a [WKScriptMessageHandler](https://developer.apple.com/library/mac/documentation/WebKit/Reference/WKScriptMessageHandler_Ref/). Both of these allowed me to inject my scraping JavaScript when the document was done loading, then pass its results to a native method for use in the rest of the app.

Here's an example version of my final code, which just gets the web page's title:

```swift
import UIKit
import WebKit

class TestClass : NSObject, WKScriptMessageHandler {
    
    private var webView = WKWebView()
    
    func startScrape() {
        let urlToScrape = NSURL(string: "http://www.apple.com/iphone")!
        let jsScrapingString = "window.webkit.messageHandlers.doneLoading.postMessage(document.title);"
        
        //Make the script be injected when the main document is done loading
        let userScript = WKUserScript(source: jsScrapingString, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: true)
        
        //Create a content controller and add the script and message handler
        let contentController = WKUserContentController()
        contentController.addUserScript(userScript)
        contentController.addScriptMessageHandler(self, name: "doneLoading")
        
        //Create a configuration for the web view
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        
        //Re-initialize the web view and load the page
        webView = WKWebView(frame: CGRectZero, configuration: config)
        webView.loadRequest(NSURLRequest(URL: urlToScrape))
    }
    
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        //None of the content loaded after this point is necessary (images, videos, etc.)
        webView.stopLoading()
        println("Received script message: \(message.body)")
    }
}

```

Calling the startScrape method above prints: "Received script message: iPhone - Apple", matching the web page's title.

Using this method decreased the time scraping took to the point where I was happy with using it in the app. In some extreme cases it sped up by about 5 seconds, changing parts of the app from unbearably slow to quick and responsive.

Feel free to use my example code or contact me if you have questions. I hope this is helpful to others in the same position I was in!