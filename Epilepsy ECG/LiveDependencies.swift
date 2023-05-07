//
//  LiveDependencies.swift
//  Epilepsy-ECG
//
//  Created by Adrian Macarenco on 04/05/2023.
//

import Foundation
import Dependencies
import PersistenceClient

extension PersistenceClient: DependencyKey {
    
    public static var liveValue: PersistenceClient {
        @Dependency(\.envVars) var envVars
        
        return .live(keyPrefix: envVars.persistenceKeyPrefix)
    }
}
