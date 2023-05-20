//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 18/05/2023.
//

import Foundation
import Dependencies
import SQLite
import DBManager
import Model

public struct DBClient {
    public var addEcg: ([(timestamp: Date, ecgData: String)]) async throws -> Void
    public var fetchRecentEcgData: (_ seconds: Int) async throws -> [EcgDTO]
    public var deleteCurrentDb:() async throws -> Void
    public init(
        addEcg: @escaping ([(timestamp: Date, ecgData: String)]) async throws -> Void,
        fetchRecentEcgData: @escaping(_ seconds: Int) async throws -> [EcgDTO],
        deleteCurrentDb: @escaping() async throws -> Void
    ) {
        self.addEcg = addEcg
        self.fetchRecentEcgData = fetchRecentEcgData
        self.deleteCurrentDb = deleteCurrentDb
    }
}


extension DBClient: DependencyKey {
    public static var liveValue: DBClient {
        
        //This directory is backed up by iTunes and iCloud, ensuring that your users won't lose their data
        let path = NSSearchPathForDirectoriesInDomains(
             .documentDirectory, .userDomainMask, true
         ).first!
        let ecgDbPath = "\(path)/ECGData.sqlite3"
        let connect = try! Connection(ecgDbPath)
 
        let dbManager = DBManager(dbConnection: connect)
        
        return .init(
            addEcg: { try await dbManager.addEcg(batch: $0)},
            fetchRecentEcgData: { try await dbManager.fetchRecentEcgData(seconds: $0)},
            deleteCurrentDb: {
                try await withCheckedThrowingContinuation { cont in
                    if FileManager.default.fileExists(atPath: ecgDbPath) {
                        do {
                            try FileManager.default.removeItem(atPath: ecgDbPath)
                            cont.resume(returning: ())
                        } catch {
                            cont.resume(throwing: error)
                        }
                    } else {
                        cont.resume(throwing: NSError(
                            domain: "dk.dtu.compute.Epilepsy-ECG",
                            code: 5000,
                            userInfo: ["ErrorMessage" : "File not found at given path"]
                        ))
                    }
                }
            }
        )
    }
}

public extension DependencyValues {
    var dbClient: DBClient {
        get { self[DBClient.self] }
        set { self[DBClient.self] = newValue }
    }
}
