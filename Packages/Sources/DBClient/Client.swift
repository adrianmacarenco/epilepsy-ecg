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
import XCTestDynamicOverlay

public struct DBClient {
    let dbPathUrl: String
    public var createUser: (_ userId: String, _ fullName: String?, _ birthday: Date?, _ gender: String?, _ weight: Double?, _ height: Double?, _ diagnosis: String?) async throws -> User
    public var getUser: (_ userId: String) async throws -> User
    public var updateUser: (_ user: User) async throws -> Void
    // Medications
    public var createMedication: (_ name: String, _ activeIngredients: [ActiveIngredient]) async throws -> Medication
    public var fetchMedications: () async throws -> [Medication]
    public var updateMedication: (_ newMedication: Medication) async throws -> Void
    public var updateMedications: (_ newMedication: [Medication]) async throws -> Void
    public var deleteMedication: (_ medicationId: Int) async throws -> Void
    
    // Intakes
    public var addIntake: (_ timestamp: Date, _ pillQuantity: Double, _ medication: Medication) async throws -> MedicationIntake
    public var updateIntake: (_ intake: MedicationIntake) async throws -> Void
    public var fetchDailyIntakes: () async throws -> [MedicationIntake]
    public var fetchIntakes: () async throws -> [MedicationIntake]
    
    // EcgEvents
    public var addEcg: ([(timestamp: Date, ecgData: String)]) async throws -> Void
    public var fetchRecentEcgData: (_ seconds: Int) async throws -> [EcgDTO]
    public var isEcgTableEmpty: () async throws -> Bool
    public var clearEcgEvents: () async throws -> Void
    public var clearDb: () async throws -> Void
    public var deleteCurrentDb: () async throws -> Void
    public init(
        dbPathUrl: String,
        createUser: @escaping (_ userId: String, _ fullName: String?, _ birthday: Date?, _ gender: String?, _ weight: Double?, _ height: Double?, _ diagnosis: String?) async throws -> User,
        getUser: @escaping (_ userId: String) async throws -> User,
        updateUser: @escaping (_ user: User) async throws -> Void,
        createMedication: @escaping (_ name: String, _ activeIngredients: [ActiveIngredient]) async throws -> Medication,
        fetchMedications: @escaping () async throws -> [Medication],
        updateMedication: @escaping (_ newMedication: Medication) async throws -> Void,
        updateMedications: @escaping (_ newMedication: [Medication]) async throws -> Void,
        deleteMedication: @escaping (_ medicationId: Int) async throws -> Void,
        addIntake: @escaping (_ timestamp: Date, _ pillQuantity: Double, _ medication: Medication) async throws -> MedicationIntake,
        updateIntake: @escaping (_ intake: MedicationIntake) async throws -> Void,
        fetchDailyIntakes: @escaping () async throws -> [MedicationIntake],
        fetchIntakes: @escaping () async throws -> [MedicationIntake],
        addEcg: @escaping ([(timestamp: Date, ecgData: String)]) async throws -> Void,
        fetchRecentEcgData: @escaping(_ seconds: Int) async throws -> [EcgDTO],
        isEcgTableEmpty: @escaping () async throws -> Bool,
        clearEcgEvents: @escaping () async throws -> Void,
        clearDb: @escaping () async throws -> Void,
        deleteCurrentDb: @escaping () async throws -> Void
    ) {
        self.dbPathUrl = dbPathUrl
        self.createUser = createUser
        self.getUser = getUser
        self.updateUser = updateUser
        self.createMedication = createMedication
        self.fetchMedications = fetchMedications
        self.updateMedication = updateMedication
        self.updateMedications = updateMedications
        self.deleteMedication = deleteMedication
        self.addIntake = addIntake
        self.updateIntake = updateIntake
        self.fetchDailyIntakes = fetchDailyIntakes
        self.fetchIntakes = fetchIntakes
        self.addEcg = addEcg
        self.fetchRecentEcgData = fetchRecentEcgData
        self.isEcgTableEmpty = isEcgTableEmpty
        self.clearEcgEvents = clearEcgEvents
        self.clearDb = clearDb
        self.deleteCurrentDb = deleteCurrentDb
    }
}

extension DBClient {
    public static func live(
        dbManager: DBManager,
        dbPathUrl: String
    ) -> Self {
        return Self(
            dbPathUrl: dbPathUrl,
            createUser: { userId, fullName, birthday, gender, weight, height, diagnosis in
                try await dbManager.addUser(userId: userId, fullName: fullName, birthday: birthday, gender: gender, weight: weight, height: height, diagnosis: diagnosis)
            },
            getUser: { try await dbManager.getUser(with: $0) },
            updateUser: { try await dbManager.updateUser($0) },
            createMedication: { medicationName, activeIngredients in
                try await dbManager.addMedication(name: medicationName, activeIngredients: activeIngredients)
            },
            fetchMedications: { try await dbManager.fetchMedications() },
            updateMedication: { try await dbManager.updateMedication($0) },
            updateMedications: { try await dbManager.updateMedications($0)},
            deleteMedication: { try await dbManager.deleteMedication(with: $0) },
            addIntake: { timeStamp, pillQuantity, medication in
                try await dbManager.addIntake(timestamp: timeStamp, pillQuantity: pillQuantity, medication: medication)
            },
            updateIntake: { try await dbManager.updateIntake($0)},
            fetchDailyIntakes: { try await dbManager.fetchDailyIntakes() },
            fetchIntakes: { try await dbManager.fetchIntakes() },
            addEcg: { try await dbManager.addEcg(batch: $0)},
            fetchRecentEcgData: { try await dbManager.fetchRecentEcgData(seconds: $0)},
            isEcgTableEmpty: dbManager.isEcgTableEmpty,
            clearEcgEvents: { try await dbManager.deleteAllEcgEvents() },
            clearDb: dbManager.clearDb,
            deleteCurrentDb: {
                try await withCheckedThrowingContinuation { cont in
                    if FileManager.default.fileExists(atPath: dbPathUrl) {
                        do {
                            try FileManager.default.removeItem(atPath: dbPathUrl)
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
//extension DBClient: DependencyKey {
//    public static var liveValue: DBClient {
//
//        //This directory is backed up by iTunes and iCloud, ensuring that your users won't lose their data
//        let path = NSSearchPathForDirectoriesInDomains(
//             .documentDirectory, .userDomainMask, true
//         ).first!
//        let ecgDbPath = "\(path)/ECGData.sqlite3"
//        let connect = try! Connection(ecgDbPath)
//
//        let dbManager = DBManager(dbConnection: connect)
//
//        return .init(
//            createUser: { userId, fullName, birthday, gender, weight, height, diagnosis in
//                try await dbManager.addUser(userId: userId, fullName: fullName, birthday: birthday, gender: gender, weight: weight, height: height, diagnosis: diagnosis)
//            },
//            getUser: { try await dbManager.getUser(with: $0) },
//            updateUser: { try await dbManager.updateUser($0) },
//            createMedication: { medicationName, activeIngredients in
//                try await dbManager.addMedication(name: medicationName, activeIngredients: activeIngredients)
//            },
//            fetchMedications: { try await dbManager.fetchMedications() },
//            updateMedication: { try await dbManager.updateMedication($0) },
//            updateMedications: { try await dbManager.updateMedications($0)},
//            deleteMedication: { try await dbManager.deleteMedication(with: $0) },
//            addIntake: { timeStamp, pillQuantity, medication in
//                try await dbManager.addIntake(timestamp: timeStamp, pillQuantity: pillQuantity, medication: medication)
//            },
//            updateIntake: { try await dbManager.updateIntake($0)},
//            fetchDailyIntakes: { try await dbManager.fetchDailyIntakes() },
//            fetchIntakes: { try await dbManager.fetchIntakes() },
//            addEcg: { try await dbManager.addEcg(batch: $0)},
//            fetchRecentEcgData: { try await dbManager.fetchRecentEcgData(seconds: $0)},
//            clearDb: dbManager.clearDb,
//            deleteCurrentDb: {
//                try await withCheckedThrowingContinuation { cont in
//                    if FileManager.default.fileExists(atPath: ecgDbPath) {
//                        do {
//                            try FileManager.default.removeItem(atPath: ecgDbPath)
//                            cont.resume(returning: ())
//                        } catch {
//                            cont.resume(throwing: error)
//                        }
//                    } else {
//                        cont.resume(throwing: NSError(
//                            domain: "dk.dtu.compute.Epilepsy-ECG",
//                            code: 5000,
//                            userInfo: ["ErrorMessage" : "File not found at given path"]
//                        ))
//                    }
//                }
//            }
//        )
//    }
//}

extension DBClient: TestDependencyKey {
    public static var testValue: DBClient {
        .failing
    }
    
    public static var previewValue: DBClient {
        .mock
    }
}

public extension DependencyValues {
    var dbClient: DBClient {
        get { self[DBClient.self] }
        set { self[DBClient.self] = newValue }
    }
}


extension DBClient {
    public static let failing = Self(
        dbPathUrl: "",
        createUser: unimplemented("createUser db file failing called"),
        getUser: unimplemented("getUser db file failing called"),
        updateUser: unimplemented("updateUser db file failing called"),
        createMedication: unimplemented("createMedication db file failing called"),
        fetchMedications: unimplemented("fetchMedications db file failing called"),
        updateMedication: unimplemented("updateMedication db file failing called"),
        updateMedications: unimplemented("updateMedications db file failing called"),
        deleteMedication: unimplemented("deleteMedication db file failing called"),
        addIntake: unimplemented("addIntake db file failing called"),
        updateIntake: unimplemented("updateIntake db file failing called"),
        fetchDailyIntakes: unimplemented("fetchDailyIntakes db file failing called"),
        fetchIntakes: unimplemented("fetchIntakes db file failing called"),
        addEcg: unimplemented("addEcg db file failing called"),
        fetchRecentEcgData: unimplemented("fetchRecentEcgData db file failing called"),
        isEcgTableEmpty: unimplemented("isEcgTableEmpty db file failing called"),
        clearEcgEvents: unimplemented("clearEcgEvents db file failing called"),
        clearDb: unimplemented("clearDb db file failing called"),
        deleteCurrentDb: unimplemented("deleteCurrentDb db file failing called"))
}
