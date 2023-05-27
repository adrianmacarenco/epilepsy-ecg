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
    public var createUser: (_ userId: String, _ fullName: String, _ birthday: Date, _ gender: String, _ weight: Double, _ height: Double, _ diagnosis: String?) async throws -> User
    public var getUser: (_ userId: String) async throws -> User
    public var createMedication: (_ name: String, _ activeIngredients: [ActiveIngredient]) async throws -> Medication
    public var updateMedication: (_ newMedication: Medication) async throws -> Void
    public var deleteMedication: (_ medicationId: Int) async throws -> Void
    public var addEcg: ([(timestamp: Date, ecgData: String)]) async throws -> Void
    public var fetchRecentEcgData: (_ seconds: Int) async throws -> [EcgDTO]
    public var deleteCurrentDb:() async throws -> Void
    public init(
        createUser: @escaping (_ userId: String, _ fullName: String, _ birthday: Date, _ gender: String, _ weight: Double, _ height: Double, _ diagnosis: String?) async throws -> User,
        getUser: @escaping (_ userId: String) async throws -> User,
        createMedication: @escaping (_ name: String, _ activeIngredients: [ActiveIngredient]) async throws -> Medication,
        updateMedication: @escaping (_ newMedication: Medication) async throws -> Void,
        deleteMedication: @escaping (_ medicationId: Int) async throws -> Void,
        addEcg: @escaping ([(timestamp: Date, ecgData: String)]) async throws -> Void,
        fetchRecentEcgData: @escaping(_ seconds: Int) async throws -> [EcgDTO],
        deleteCurrentDb: @escaping() async throws -> Void
    ) {
        self.createUser = createUser
        self.getUser = getUser
        self.createMedication = createMedication
        self.updateMedication = updateMedication
        self.deleteMedication = deleteMedication
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
            createUser: { userId, fullName, birthday, gender, weight, height, diagnosis in
                try await dbManager.addUser(userId: userId, fullName: fullName, birthday: birthday, gender: gender, weight: weight, height: height, diagnosis: diagnosis)
            },
            getUser: { userId in try await dbManager.getUser(with: userId)},
            createMedication: { medicationName, activeIngredients in
                try await dbManager.addMedication(name: medicationName, activeIngredients: activeIngredients)
            },
            updateMedication: { try await dbManager.updateMedication($0) },
            deleteMedication: { try await dbManager.deleteMedication(with: $0) },
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
