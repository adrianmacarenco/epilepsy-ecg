//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 01/06/2023.
//

import Foundation

public class FileUploader: NSObject {
    
    public func uploadFile(
        at fileURL: URL,
        at targetURL: URL
    ) async throws -> Void {
        var request = URLRequest(
            url: targetURL,
            cachePolicy: .reloadIgnoringLocalCacheData
        )
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("study-id", forHTTPHeaderField: "d5f7ab8c-9f27-4b50-9cf5-eb3a19ca993e")

        return try await withCheckedThrowingContinuation { cont in
            let uploadTask = URLSession.shared.uploadTask(
                with: request, fromFile: fileURL
            ) { data, response, error in
                
                guard let error else {
                    cont.resume(returning: ())
                    return
                }
                cont.resume(throwing: error)
            }
            uploadTask.resume()
        }
        
    }
}
