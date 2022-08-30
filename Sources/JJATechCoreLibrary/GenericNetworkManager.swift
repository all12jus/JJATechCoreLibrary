//
//  File.swift
//  
//
//  Created by Justin Allen on 8/29/22.
//

import Foundation

@available(iOS 15.0, *)
public class GenericNetworkManager<T: FormEditable> {
    let baseURLSting: String = "https://bb60e4e8ea0a.ngrok.io/"
    let decoder = JSONDecoder()
    let encoder = JSONEncoder()
    
    public init() {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        decoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
            if let date = formatter.date(from: dateStr) {
                return date
            }
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
            if let date = formatter.date(from: dateStr) {
                return date
            }
            throw DateError.invalidDate
        })
        
        encoder.dateEncodingStrategy = .iso8601
    }
    
    public func getAll() async throws -> [T] {
        let urlString = "\(baseURLSting)\(T.getEndpoint())"
        guard let url = URL(string: urlString) else { throw NetworkError.invalidURL }
//        print(url.absoluteString)
        
        let (data, response) = try await URLSession.shared.data(for: URLRequest(url: url))
        guard let response = response as? HTTPURLResponse  else {
            throw NetworkError.invalidResponse
        }
        
        if response.statusCode != 200 {
            print("Error: \(response.statusCode)")
            throw NetworkError.invalidStatusCode(response.statusCode)
        }
        
        do {
            // print string from data
//            let string = String(data: data, encoding: .utf8)
//            print(string)
            let repo = try decoder.decode([T].self, from: data)
            return repo
        } catch {
            print(error)
            throw NetworkError.invalidJSON
        }
    }
    
    // POST vehicle
    public func post(item: T) async throws {
        let urlString = "\(baseURLSting)\(T.getEndpoint())"
        guard let url = URL(string: urlString) else { throw NetworkError.invalidURL }
//        print(url.absoluteString)
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = try encoder.encode(item)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (_, response) = try await URLSession.shared.data(for: urlRequest)
        guard let response = response as? HTTPURLResponse  else {
            throw NetworkError.invalidResponse
        }
        
        if response.statusCode != 200 {
            print("Error: \(response.statusCode)")
            throw NetworkError.invalidStatusCode(response.statusCode)
        }
    }
    
    // PUT vehicle
    public func put(item: T) async throws {
        guard let id = item.getDatabaseID() else { throw NetworkError.invalidID }
        let urlString = "\(baseURLSting)\(T.getEndpoint())/\(id)"
        guard let url = URL(string: urlString) else { throw NetworkError.invalidURL }
//        print(url.absoluteString)
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.httpBody = try encoder.encode(item)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (_, response) = try await URLSession.shared.data(for: urlRequest)
        guard let response = response as? HTTPURLResponse  else {
            throw NetworkError.invalidResponse
        }
        
        if response.statusCode != 200 {
            print("Error: \(response.statusCode)")
            throw NetworkError.invalidStatusCode(response.statusCode)
        }
    }
    
    public func save(_ item: T) async throws {
        if item.isNew() {
            let _ = try await self.post(item: item)
//            print("create result: \(result)")
        } else {
            let _ = try await self.put(item: item)
//            print("update result: \(result)")
        }
    }
    
    public func save(_ item: T, callback: @escaping (Bool) -> Void) {
        Task.init {
            do {
                try await save(item)
                callback(true)
            } catch {
                print(error)
                callback(false)
            }
        }
    }
    
    public func delete(item: T) async throws {
        guard let id = item.getDatabaseID() else { throw NetworkError.invalidID }
        let urlString = "\(baseURLSting)\(T.getEndpoint())/\(id)"
        guard let url = URL(string: urlString) else { throw NetworkError.invalidURL }
        print(url.absoluteString)
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        
        let (_, response) = try await URLSession.shared.data(for: urlRequest)
        guard let response = response as? HTTPURLResponse  else {
            throw NetworkError.invalidResponse
        }
        
        if response.statusCode != 200 {
            print("Error: \(response.statusCode)")
            throw NetworkError.invalidStatusCode(response.statusCode)
        }
        
        print("delete result: \(response.statusCode)")
    }
}

public enum DateError: String, Error {
    case invalidDate
}

public enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case invalidStatusCode(Int)
    case invalidJSON
    case invalidID
}
