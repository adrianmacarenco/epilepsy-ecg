//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 01/06/2023.
//

import Foundation
import Dependencies

extension APIClient: TestDependencyKey {
    public static var testValue: APIClient {
        .failing
    }
    
    public static var previewValue: APIClient {
        .mock
    }
}

public extension DependencyValues {
    var apiClient: APIClient {
        get { self[APIClient.self] }
        set { self[APIClient.self] = newValue }
    }
}
