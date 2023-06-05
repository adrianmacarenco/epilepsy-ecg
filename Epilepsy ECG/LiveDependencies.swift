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
import DBClient
import DBManager
import SQLite

extension PersistenceClient: DependencyKey {
    
    public static var liveValue: PersistenceClient {
        @Dependency(\.envVars) var envVars
        
        return .live(keyPrefix: envVars.persistenceKeyPrefix)
    }
}

extension APIClient: DependencyKey {
    public static var liveValue: APIClient {
        @Dependency(\.envVars) var envVars
        @Dependency(\.persistenceClient) var persistenceClient
        
        let user = persistenceClient.user.load()!
        
        let authHandler = AuthenticationHandlerAsync(
            getTokeUrl: URL(string: "https://cans.cachet.dk/oauth/token")!,
            getTokens: persistenceClient.apiTokenWrapper.load,
            saveTokens: { persistenceClient.apiTokenWrapper.save($0) },
            carpUsername: envVars.carpUserName,
            carpPassword: envVars.carpPassword,
            userId: user.id
        )
        return APIClient.live(baseUrl: envVars.baseUrl, authenticationHandler: authHandler)
    }
}

extension DBClient: DependencyKey {

    public static var liveValue: DBClient {
        @Dependency(\.envVars) var envVars

        let ecgDbPath = "\(envVars.dbBasePath)/ECGData.sqlite3"
        let connection = try! Connection(ecgDbPath)
        let dbManager = DBManager(dbConnection: connection)
        return .live(dbManager: dbManager, dbPathUrl: ecgDbPath)
    }
}
