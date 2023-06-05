//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 04/06/2023.
//

import Foundation

/// Request for posting
/// - Parameters:
///   - url: url + path to hit
///   - requestBody: the body to be encoded to json
///   - encoder: supply custom encoder if needed
/// - Returns: Request
public func makePostRequest(
    url: URL
) -> URLRequest {
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    let boundary = UUID().uuidString
//    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    return request
}
