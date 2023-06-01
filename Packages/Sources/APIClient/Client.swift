//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 01/06/2023.
//

import Foundation
import XCTestDynamicOverlay

public struct APIClient {
    public var uploadDbFile: () async throws -> Void
    
    public init(
        uploadDbFile: @escaping () async throws -> Void
    ) {
        self.uploadDbFile = uploadDbFile
    }
}


extension APIClient {
    public static let failing = APIClient(
        uploadDbFile: unimplemented("upload db file failing called")
    )
}
