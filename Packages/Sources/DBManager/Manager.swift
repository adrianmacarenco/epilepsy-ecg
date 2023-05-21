//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 18/05/2023.
//

import Foundation
import SQLite
import Model

enum DatabaseError: Error {
    case generalError(message: String)
}

public class DBManager: NSObject {
    let dbConnection: Connection
    
    // Define tables and columns
    private let medications = Table("medications")
    private let id = Expression<Int64>("id")
    private let name = Expression<String>("name")
    private let activeIngredientQuantity = Expression<Double>("active_ingredient_quantity")
    
    private let intakes = Table("intakes")
    private let timestamp = Expression<Date>("timestamp")
    private let pillQuantity = Expression<Double>("pill_quantity")
    private let medicationId = Expression<Int64>("medication_id")
    
    private let ecgEvents = Table("ecgevents")
    private let ecgTimestamp = Expression<Date>("timestamp")
    private let ecgData = Expression<String>("ecg_data")
    
    private let users = Table("users")
    private let fullName = Expression<String>("full_name")
    private let birthday = Expression<Date>("birthday")
    private let gender = Expression<String>("gender")
    private let weight = Expression<Double>("weight")
    private let height = Expression<Double>("height")
    private let diagnosis = Expression<String>("diagnosis")

    
    public init(dbConnection: Connection) {
        self.dbConnection = dbConnection
        super.init()
        print("Creating tables..... 🤌")
        
        do {
            try dbConnection.run(medications.create { [weak self] t in
                guard let self else { return }
                t.column(self.id, primaryKey: .autoincrement)
                t.column(self.name)
                t.column(self.activeIngredientQuantity)
            })
        } catch {
            print("Medications table is already created: \n \(error.localizedDescription) 📑")
        }
        do {
            try dbConnection.run(intakes.create { [weak self] t in
                guard let self else { return }
                t.column(self.id, primaryKey: .autoincrement)
                t.column(self.timestamp)
                t.column(self.pillQuantity)
                t.column(self.medicationId, references: medications, id)
            })
        } catch {
            print("intakes table is already created: \n \(error.localizedDescription) 📑")
        }
        
        do {
            try dbConnection.run(ecgEvents.create { [weak self] t in
                guard let self else { return }
                t.column(self.id, primaryKey: .autoincrement)
                t.column(self.ecgTimestamp)
                t.column(self.ecgData)
            })
        } catch {
            print("ecgEvents table is already created: \n \(error.localizedDescription) 📑")
        }
    }
    
    // MARK: - User Entity
    
    public func addUser(fullName: String, birthday: Date, gender: String, weight: Double, height: Double, diagnosis: String) async throws -> User {
        return try await withCheckedThrowingContinuation { cont in
            do {
                let insert = users.insert(self.fullName <- fullName, self.birthday <- birthday, self.gender <- gender, self.weight <- weight, self.height <- height, self.diagnosis <- diagnosis)
                let rowId = try dbConnection.run(insert)
                cont.resume(returning: .init(
                    id: Int(rowId),
                    fullName: fullName,
                    birthday: birthday,
                    gender: gender,
                    weight: weight,
                    height: height,
                    diagnosis: diagnosis
                ))
            } catch {
                cont.resume(throwing: error)
            }
        }
    }
    
    public func updateUser(_ user: User) async throws -> Void {
        return try await withCheckedThrowingContinuation { cont in
            do {
                let dbUser = users.filter(id == Int64(user.id))
                let update = dbUser.update(self.fullName <- user.fullName, self.birthday <- user.birthday, self.gender <- user.gender, self.weight <- user.weight, self.height <- user.height, self.diagnosis <- user.diagnosis)
                try dbConnection.run(update)
                cont.resume(returning: ())
            } catch {
                cont.resume(throwing: error)
            }
        }
    }

    public func deleteUser(with id: Int) async throws -> Void {
        return try await withCheckedThrowingContinuation { cont in
            do {
                let dbUser = users.filter(self.id == Int64(id))
                let delete = dbUser.delete()
                try dbConnection.run(delete)
                cont.resume(returning: ())
            } catch {
                cont.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Medication Entity
    public func fetchMedications() async throws -> [Medication] {
        return try await withCheckedThrowingContinuation { cont in
            do {
                var medicationsResult: [Medication] = []
                for medicationRow in try dbConnection.prepare(medications) {
                    medicationsResult.append(.init(
                        id: Int(medicationRow[id]),
                        name: medicationRow[name],
                        activeIngredientQuantity: medicationRow[activeIngredientQuantity]
                    ))
                }
                cont.resume(returning: medicationsResult)
            } catch {
                cont.resume(throwing: error)
            }
        }
    }
    
    public func addMedication(name: String, activeIngredientQuantity: Double) async throws -> Medication {
        return try await withCheckedThrowingContinuation { cont in
            do {
                let insert = medications.insert(self.name <- name, self.activeIngredientQuantity <- activeIngredientQuantity)
                let rowId = try dbConnection.run(insert)
                cont.resume(returning: .init(
                    id: Int(rowId),
                    name: name,
                    activeIngredientQuantity: activeIngredientQuantity
                ))
            } catch {
                cont.resume(throwing: error)
            }
        }
    }
    
    public func updateMedication(_ medication: Medication) async throws -> Void {
        return try await withCheckedThrowingContinuation { cont in
            do {
                let dbMedication = medications.filter(id == Int64(medication.id))
                let update = dbMedication.update(self.name <- medication.name, self.activeIngredientQuantity <- medication.activeIngredientQuantity)
                try dbConnection.run(update)
                cont.resume(returning: ())
            } catch {
                cont.resume(throwing: error)
            }
        }
    }
    
    public func deleteMedication(with id: Int) async throws -> Void {
        return try await withCheckedThrowingContinuation { cont in
            do {
                let dbMedication = medications.filter(self.id == Int64(id))
                let delete = dbMedication.delete()
                try dbConnection.run(delete)
                cont.resume(returning: ())
            } catch {
                cont.resume(throwing: error)
            }
        }
    }
        
    //MARK: - Intake Entity
    public func fetchIntakes() async throws -> [MedicationIntake] {
        return try await withCheckedThrowingContinuation { cont in
            do {
                var intakesResult: [MedicationIntake] = []
                for intakeRow in try dbConnection.prepare(intakes) {
                    intakesResult.append(MedicationIntake(
                        id: Int(intakeRow[id]),
                        timestamp: intakeRow[timestamp],
                        pillQuantity: intakeRow[pillQuantity],
                        medicationId: Int(intakeRow[medicationId])
                    ))
                }
                cont.resume(returning: intakesResult)
            } catch {
                cont.resume(throwing: error)
            }
        }
    }
    
    public func addIntake(timestamp: Date, pillQuantity: Double, medicationId: Int) async throws -> MedicationIntake {
        return try await withCheckedThrowingContinuation { cont in
            do {
                let insert = intakes.insert(self.timestamp <- timestamp, self.pillQuantity <- pillQuantity, self.id <- Int64(medicationId))
                let rowId = try dbConnection.run(insert)
                cont.resume(returning: .init(
                    id: Int(rowId),
                    timestamp: timestamp,
                    pillQuantity: pillQuantity,
                    medicationId: medicationId
                ))
            } catch {
                cont.resume(throwing: error)
            }
        }
    }
    
    public func updateIntake(_ intake: MedicationIntake) async throws -> Void {
        return try await withCheckedThrowingContinuation { cont in
            do {
                let dbMedication = medications.filter(id == Int64(intake.id))
                let update = dbMedication.update(self.timestamp <- intake.timestamp, self.pillQuantity <- intake.pillQuantity, self.medicationId <- Int64(intake.medicationId))
                try dbConnection.run(update)
                cont.resume(returning: ())
            } catch {
                cont.resume(throwing: error)
            }
        }
    }
    
    public func deleteIntake(with id: Int) async throws -> Void {
        return try await withCheckedThrowingContinuation { cont in
            do {
                let dbMedication = intakes.filter(self.id == Int64(id))
                let delete = dbMedication.delete()
                try dbConnection.run(delete)
                cont.resume(returning: ())
            } catch {
                cont.resume(throwing: error)
            }
        }
    }
    
    //MARK: - ECGEvent Entity
    public func addEcg(batch: [(timestamp: Date, ecgData: String)]) async throws -> Void {
        return try await withCheckedThrowingContinuation { cont in
            do {
                var setters = [[Setter]]()
                for item in batch {
                    setters.append([self.ecgTimestamp <- item.timestamp, self.ecgData <- item.ecgData])
                }
                let insertedIds = ecgEvents.insertMany(setters)
                
                let _ = try dbConnection.run(insertedIds)
                cont.resume(returning: ())
                
            } catch {
                cont.resume(throwing: error)
            }
        }
    }
    
    
    public func fetchRecentEcgData(seconds: Int) async throws -> [EcgDTO] {
        return try await withCheckedThrowingContinuation { cont in
            do {
                for ecgRow in try dbConnection.prepare(ecgEvents) {
                    print("\(ecgRow[ecgTimestamp]) \(ecgRow[ecgData])  🌈")
                }
                print("IS there anyhting?")
                let now = Date()
                
                let query = ecgEvents.filter(self.ecgTimestamp > now).order(self.ecgTimestamp.desc)
                let rows = try dbConnection.prepare(query)
                var result: [EcgDTO] = []
                
                for row in rows {
                    let timestamp = row[self.ecgTimestamp]
                    let ecgData = row[self.ecgData]
                    result.append(EcgDTO(
                        timestamp: timestamp,
                        stringData: ecgData
                    ))
                }
                
                cont.resume(returning: result)
            } catch {
                cont.resume(throwing: error)
            }
        }
    }
    
    public func fetchEcg() async throws -> [EcgDTO] {
        return try await withCheckedThrowingContinuation { cont in
            do {
                var ecgResult: [EcgDTO] = []
                for ecgRow in try dbConnection.prepare(ecgEvents) {
                    ecgResult.append(.init(
                        timestamp: ecgRow[ecgTimestamp],
                        stringData: ecgRow[ecgData]
                    ))
                }
                cont.resume(returning: ecgResult)
            } catch {
                cont.resume(throwing: error)
            }
        }
    }
}
