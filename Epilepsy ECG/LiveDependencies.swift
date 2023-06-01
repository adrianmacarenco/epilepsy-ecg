//
//  LiveDependencies.swift
//  Epilepsy-ECG
//
//  Created by Adrian Macarenco on 04/05/2023.
//

import Foundation
import Dependencies
import PersistenceClient
import APIClient
import APIClientLive

extension PersistenceClient: DependencyKey {
    
    public static var liveValue: PersistenceClient {
        @Dependency(\.envVars) var envVars
        
        return .live(keyPrefix: envVars.persistenceKeyPrefix)
    }
}

extension APIClient: DependencyKey {
    public static var liveValue: APIClient {
        @Dependency(\.envVars) var envVars

        return APIClient.live(baseUrl: envVars.baseUrl)
    }
}
