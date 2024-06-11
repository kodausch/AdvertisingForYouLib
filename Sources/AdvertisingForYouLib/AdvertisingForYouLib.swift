// The Swift Programming Language
// https://docs.swift.org/swift-book
import UIKit
import WebKit

public class AdWebViewController: UIViewController {

    private var webView: WKWebView!
    private var url: URL

    public init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        view = webView
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

extension AdWebViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Finished loading: \(url)")
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Failed to load: \(url), error: \(error.localizedDescription)")
    }
}

import WebKit

public final class AdFetcher {
    
    public init() {}
    
    private func check(url: String, completion: @escaping (Result<Data, AdvClientError>) -> Void) {
        self.makeRequest(url: url, completion: completion)
    }
    
    public func makeRequest(url: String, completion: @escaping (Result<Data, AdvClientError>) -> Void) {
        let url = URL(string: url)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let session: URLSession = {
            let session = URLSession(configuration: .default)
            session.configuration.timeoutIntervalForRequest = 10.0
            return session
        }()
        let task = session.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                completion(.failure(.httpError(httpResponse.statusCode)))
                return
            }
            guard error == nil, let data = data else {
                completion(.failure(.responseError))
                return
            }
            completion(.success(data))
        }
        task.resume()
    }
    
    public func fetchRelevantAd(source: String, 
                                keyword: String,
                                appsId: String,
                                idfa: String,
                                completion: @escaping (String) -> Void) {
        var resultedString = UserDefaults.standard.string(forKey: "advert")
        if let validResultedString = resultedString {
            completion(validResultedString)
            return
        }
        
        self.check(url: source) { result in
            let gaid = appsId
            let idfa = idfa
            switch result {
            case .success(let data):
                let responseString = String(data: data, encoding: .utf8) ?? ""
                if responseString.contains(keyword) {
                    let link = "\(responseString)?idfa=\(idfa)&gaid=\(gaid)"
                    resultedString = link
                    UserDefaults.standard.setValue(link, forKey: "advert")
                    completion(link)
                } else {
                    completion(resultedString ?? "")
                }
            case .failure(_):
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    completion(resultedString ?? "")
                }
            }
        }
    }
    
    public func fetchAndPresentAd(from viewController: UIViewController,
                                      source: String,
                                      keyword: String,
                                      appsId: String,
                                      idfa: String,
                                      completion: @escaping (Bool) -> Void) {
            fetchRelevantAd(source: source, keyword: keyword, appsId: appsId, idfa: idfa) { [weak self] urlString in
                guard let self = self else { return }
                
                if !urlString.isEmpty, let url = URL(string: urlString) {
                    DispatchQueue.main.async {
                        let webViewController = AdWebViewController(url: url)
                        viewController.present(webViewController, animated: true, completion: nil)
                        completion(true)
                    }
                } else {
                    completion(false)
                }
            }
        }
}

public enum AdvClientError: Error {
    case responseError
    case noDataError
    case httpError(Int)
}
