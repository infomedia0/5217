import Foundation

enum QuoteEndpoint {
    static let url = URL(string: "https://zenquotes.io/api/quotes")!
    static let maximumBytes = 131_072
    static func allows(_ url: URL?) -> Bool {
        guard let url else { return false }
        return url.scheme == "https" && url.host == "zenquotes.io" &&
            (url.port == nil || url.port == 443) && url.path == "/api/quotes" &&
            url.user == nil && url.password == nil && url.query == nil && url.fragment == nil
    }
}

struct QuoteHTTPClient {
    let configuration: URLSessionConfiguration
    init(configuration: URLSessionConfiguration = .ephemeral) { self.configuration = configuration }
    func fetch(completion: @escaping (Result<Data, Error>) -> Void) {
        BoundedQuoteRequest(configuration: configuration, completion: completion).start()
    }
}

/// One request owns one serial delegate queue. Mutable fields are initialized
/// before resume, then accessed only on that queue; no shared delegate state.
private final class BoundedQuoteRequest: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    private let configuration: URLSessionConfiguration
    private var session: URLSession?
    private var completion: ((Result<Data, Error>) -> Void)?
    private var body = Data()

    init(configuration: URLSessionConfiguration, completion: @escaping (Result<Data, Error>) -> Void) {
        self.configuration = (configuration.copy() as? URLSessionConfiguration) ?? .ephemeral
        self.completion = completion
    }

    func start() {
        configuration.timeoutIntervalForRequest = 12
        configuration.timeoutIntervalForResource = 15
        configuration.httpShouldSetCookies = false
        configuration.httpCookieStorage = nil
        configuration.urlCredentialStorage = nil
        configuration.urlCache = nil
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: queue)
        var request = URLRequest(url: QuoteEndpoint.url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("5217/2.4.7", forHTTPHeaderField: "User-Agent")
        session?.dataTask(with: request).resume()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil)
        finish(.failure(QuoteAPIError.redirectRejected))
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let response = response as? HTTPURLResponse, QuoteEndpoint.allows(response.url) else {
            completionHandler(.cancel); finish(.failure(QuoteAPIError.invalidResponse)); return
        }
        guard response.statusCode == 200 else {
            completionHandler(.cancel); finish(.failure(QuoteAPIError.http(response.statusCode))); return
        }
        guard response.mimeType?.lowercased() == "application/json" else {
            completionHandler(.cancel); finish(.failure(QuoteAPIError.invalidResponse)); return
        }
        guard response.expectedContentLength <= QuoteEndpoint.maximumBytes else {
            completionHandler(.cancel); finish(.failure(QuoteAPIError.responseTooLarge)); return
        }
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard completion != nil else { return }
        guard data.count <= QuoteEndpoint.maximumBytes - body.count else {
            finish(.failure(QuoteAPIError.responseTooLarge)); return
        }
        body.append(data)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error { finish(.failure(error)) }
        else { finish(.success(body)) }
    }

    private func finish(_ result: Result<Data, Error>) {
        guard let callback = completion else { return }
        completion = nil
        body.removeAll()
        session?.invalidateAndCancel()
        session = nil
        callback(result)
    }
}
