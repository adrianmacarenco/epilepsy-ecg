//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 03/06/2023.
//

import Foundation
import Model

public actor AuthenticationHandlerAsync {
    
    var apiTokens: ApiTokenWrapper? {
        get { getTokens() }
        set { saveTokens(newValue) }
    }
    let getTokens: () -> ApiTokenWrapper?
    private var getTokenUrl: URL
    var networkRequest:
    (URLRequest) async throws -> (Data, URLResponse) = URLSession.shared.data(for: )
    let saveTokens: (ApiTokenWrapper?) -> Void
    var now: () -> Date = Date.init
    let carpUsername: String
    let carpPassword: String
    let userId: String
    
    public init(
        getTokeUrl: URL,
        getTokens: @escaping () -> ApiTokenWrapper?,
        saveTokens: @escaping (ApiTokenWrapper?) -> Void,
        now: @escaping () -> Date = Date.init,
        networkRequest: @escaping (URLRequest) async throws -> (Data, URLResponse) = URLSession.shared.data(for: ),
        carpUsername: String,
        carpPassword: String,
        userId: String
    ) {
        self.getTokenUrl = getTokeUrl
        self.getTokens = getTokens
        self.saveTokens = saveTokens
        self.now = now
        self.networkRequest = networkRequest
        self.carpUsername = carpUsername
        self.carpPassword = carpPassword
        self.userId = userId
    }
    
    func validTokens() async throws -> ApiTokenWrapper {
        if let apiTokens, apiTokens.isValid(now: now()) {
            return apiTokens
        } else {
            let newTokens = try await Self.getNewAccessToken(
                getTokenUrl: getTokenUrl,
                carpUsername: self.carpUsername,
                carpPassword: self.carpPassword,
                networkRequest: self.networkRequest)
            apiTokens = newTokens
            return newTokens
        }
    }
    
    static func getNewAccessToken(
        getTokenUrl: URL,
        carpUsername: String,
        carpPassword: String,
        networkRequest: (URLRequest) async throws -> (Data, URLResponse)
    ) async throws -> ApiTokenWrapper {
        
        let decoder = JSONDecoder()
        var request = URLRequest(url: getTokenUrl)
        let data = "client_id=carp&client_secret=carp&grant_type=password&username=\(carpUsername)&password=\(carpPassword)".data(using: .utf8)

        request.httpMethod = "POST"
        request.httpBody = data
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField:"Content-Type");
        request.setValue("Basic Y2FycDpjYXJw", forHTTPHeaderField: "Authorization")
        let response = try await networkRequest(request)
        print("⭐️ GetToken response data: \(String(data: response.0, encoding: .utf8)!)")
        if let code = (response.1 as? HTTPURLResponse)?.statusCode,
           code == 401 {
            throw URLError(.userAuthenticationRequired)
        }
        
        return try decoder.decode(ApiTokenWrapper.self, from: response.0)
    }
    
    /// Authenticates URLRequests
    /// - Parameter request: Requests to be authenticated
    /// - Returns: The result of the request
    public func performAuthenticatedRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        
        do {
            let tokens = try await validTokens()
            
            do {
                let response = try await performAuthenticatedRequest(request, accessToken: tokens.accessToken)
                if
                    let code = (response.1 as? HTTPURLResponse)?.statusCode,
                    code == 401 {
                    throw URLError(.userAuthenticationRequired)
                }
                return response
            } catch let error as URLError where error.code == .userAuthenticationRequired {
                let newTokens = try await Self.getNewAccessToken(
                    getTokenUrl: getTokenUrl,
                    carpUsername: self.carpUsername,
                    carpPassword: self.carpPassword,
                    networkRequest: self.networkRequest
                )
                self.apiTokens = newTokens
                let response = try await performAuthenticatedRequest(request, accessToken: newTokens.accessToken)
                return response
            }
        } catch {
            apiTokens = nil
            throw error
        }
    }
    
    
    /// Authenticates URLRequests
    /// - Parameter request: Requests to be authenticated
    /// - Returns: The result of the request
    public func performAuthenticatedUploadRequest(_ request: URLRequest, _ fromFile: URL) async throws -> (Data, URLResponse) {
        
        do {
            let tokens = try await validTokens()
            
            do {
                let response = try await performAuthenticatedUploadRequest(request, fromFile, accessToken: tokens.accessToken)
                if
                    let code = (response.1 as? HTTPURLResponse)?.statusCode,
                    code == 401 {
                    throw URLError(.userAuthenticationRequired)
                }
                return response
            } catch let error as URLError where error.code == .userAuthenticationRequired {
                let newTokens = try await Self.getNewAccessToken(
                    getTokenUrl: getTokenUrl,
                    carpUsername: self.carpUsername,
                    carpPassword: self.carpPassword,
                    networkRequest: self.networkRequest
                )
                self.apiTokens = newTokens
                let response = try await performAuthenticatedUploadRequest(request, fromFile, accessToken: newTokens.accessToken)
                return response
            }
        } catch {
            apiTokens = nil
            throw error
        }
    }
    
    /// Adds access token to request
    /// throws auth error if provided token should be invalid
    private func performAuthenticatedRequest(
        _ request: URLRequest,
        accessToken: String
    ) async throws -> (Data, URLResponse) {
        var request = request
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        return try await networkRequest(request)
    }
    
    private func performAuthenticatedUploadRequest(
        _ request: URLRequest,
        _ fromFile: URL,
        accessToken: String
    ) async throws -> (Data, URLResponse) {
        var request = request

        
        let dbData: Data
        
        do {
            dbData = try Data(contentsOf: fromFile)
        } catch {
            throw error
        }
        
        // generate boundary string using a unique per-app string
        let boundary = UUID().uuidString
        request.httpMethod = "POST"
        
        // Set Content-Type Header to multipart/form-data, this is equivalent to submitting form data with file upload in a web browser
        // And the boundary is also set here
        var data = Data()
        let name = "file"
        let filename = "\(userId)_\(Int(now().timeIntervalSince1970).description).sqlite3"

        // Add the dbfile data to the raw http request data
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: application/vnd.sqlite3\r\n\r\n".data(using: .utf8)!)
        data.append(dbData)

        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        return try await URLSession.shared.upload(for: request, from: data)
    }
}

extension ApiTokenWrapper {
    func isValid(now: Date) -> Bool {
        self.expiryDate > now
    }
}
