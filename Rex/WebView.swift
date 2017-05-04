import UIKit
import OAuthSwift

class WebView: OAuthWebViewController {
    
    typealias WebView = UIWebView
    
    var targetURL : URL = URL()
    let webView : WebView = WebView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.webView.frame = UIScreen.main.bounds
        self.webView.scalesPageToFit = true
        self.webView.delegate = self
        self.view.addSubview(self.webView)
        loadAddressURL()

    }
    
    override func handle(_ url: URL) {
        targetURL = url
        super.handle(url)
        
        loadAddressURL()
    }
    
    func loadAddressURL() {
        let req = URLRequest(url: targetURL)
        self.webView.loadRequest(req)
    }
    
}

extension WebView: UIWebViewDelegate {
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let url = request.url, (url.scheme == "rexapp"){
            self.dismissWebViewController()
        }
        return true
    }
}
