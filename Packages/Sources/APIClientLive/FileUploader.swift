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
//        request.addValue("study-id", forHTTPHeaderField: "5300a9b7-204b-4c6b-8757-fec603507200")

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
