import Foundation

enum BWClientError: Error {
    case invalidURL
    case httpError(Int)
    case noData
    case networkError(Error)
}

final class BWClient: @unchecked Sendable {
    nonisolated(unsafe) static let shared = BWClient()

    private let baseURL: String
    private let session: URLSession

    init(baseURL: String = "http://localhost:8087") {
        self.baseURL = baseURL
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 5
        session = URLSession(configuration: config)
    }

    func get(_ path: String) throws -> Data {
        let req = try makeRequest(method: "GET", path: path, body: nil)
        return try execute(req)
    }

    func post(_ path: String, body: Data? = nil) throws -> Data {
        let req = try makeRequest(method: "POST", path: path, body: body)
        return try execute(req)
    }

    func put(_ path: String, body: Data? = nil) throws -> Data {
        let req = try makeRequest(method: "PUT", path: path, body: body)
        return try execute(req)
    }

    func delete(_ path: String) throws -> Data {
        let req = try makeRequest(method: "DELETE", path: path, body: nil)
        return try execute(req)
    }

    private func makeRequest(method: String, path: String, body: Data?) throws -> URLRequest {
        guard let url = URL(string: baseURL + path) else {
            throw BWClientError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        if let body = body {
            req.httpBody = body
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return req
    }

    private func execute(_ request: URLRequest) throws -> Data {
        var result: Result<Data, Error>?
        let sem = DispatchSemaphore(value: 0)
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                result = .failure(BWClientError.networkError(error))
            } else if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
                result = .failure(BWClientError.httpError(http.statusCode))
            } else if let data = data {
                result = .success(data)
            } else {
                result = .failure(BWClientError.noData)
            }
            sem.signal()
        }.resume()
        sem.wait()
        return try result!.get()
    }
}
