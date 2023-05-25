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

    private let activeIngredients = Table("active_ingredients")
    private let activeIngredientQuantity = Expression<Double>("active_ingredient_quantity")
    private let unit = Expression<String>("unit")

    private let intakes = Table("intakes")
    private let timestamp = Expression<Date>("timestamp")
    private let pillQuantity = Expression<Double>("pill_quantity")
    private let medicationId = Expression<Int64>("medication_id")
    
    private let ecgEvents = Table("ecgevents")
    private let ecgTimestamp = Expression<Date>("timestamp")
    private let ecgData = Expression<String>("ecg_data")
    
    private let users = Table("users")
    private let userId = Expression<String>("id")
    private let fullName = Expression<String>("full_name")
    private let birthday = Expression<Date>("birthday")
    private let gender = Expression<String>("gender")
    private let weight = Expression<Double>("weight")
    private let height = Expression<Double>("height")
    private let diagnosis = Expression<String?>("diagnosis")
    
    public init(dbConnection: Connection) {
        self.dbConnection = dbConnection
        super.init()
        print("Creating tables..... 🤌")
        
        do {
            try dbConnection.run(medications.create { [weak self] t in
                guard let self else { return }
                t.column(self.id, primaryKey: .autoincrement)
                t.column(self.name)
            })
        } catch {
            print("Medications table is already created: \n \(error.localizedDescription) 📑")
        }
        
        do {
            try dbConnection.run(activeIngredients.create { [weak self] t in
                guard let self else { return }
                t.column(self.id, primaryKey: .autoincrement)
                t.column(self.name)
                t.column(self.activeIngredientQuantity)
                t.column(self.unit)
                t.column(self.medicationId, references: medications, id)
            })
        } catch {
            print("ActiveIngredients table is already created: \n \(error.localizedDescription) 📑")
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
        
        createEcgTable()
        
        do {
            try dbConnection.run(users.create { t in
                t.column(userId, primaryKey: true)
                t.column(fullName)
                t.column(birthday)
                t.column(gender)
                t.column(weight)
                t.column(height)
                t.column(diagnosis)
            })
        } catch {
            print("Failed to create users table: \(error)")
        }
    }
    
    func createEcgTable() {
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
    
    public func addUser(userId: String, fullName: String, birthday: Date, gender: String, weight: Double, height: Double, diagnosis: String?) async throws -> User {
        return try await withCheckedThrowingContinuation { cont in
            do {
                let insert = users.insert(self.userId <- userId, self.fullName <- fullName, self.birthday <- birthday, self.gender <- gender, self.weight <- weight, self.height <- height, self.diagnosis <- diagnosis)
                _ = try dbConnection.run(insert)
                cont.resume(returning: .init(
                    id: userId,
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
                let dbUser = users.filter(userId == user.id)
                let update = dbUser.update(self.fullName <- user.fullName, self.birthday <- user.birthday, self.gender <- user.gender, self.weight <- user.weight, self.height <- user.height, self.diagnosis <- user.diagnosis)
                try dbConnection.run(update)
                cont.resume(returning: ())
            } catch {
                cont.resume(throwing: error)
            }
        }
    }

    public func deleteUser(with id: String) async throws -> Void {
        return try await withCheckedThrowingContinuation { cont in
            do {
                let dbUser = users.filter(self.userId == id)
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
                    let medicationId = Int(medicationRow[id])
                    let activeIngredients = try fetchActiveIngredients(for: medicationId)
                    let medication = Medication(
                        id: medicationId,
                        name: medicationRow[name],
                        activeIngredients: activeIngredients
                    )
                    medicationsResult.append(medication)
                }
                cont.resume(returning: medicationsResult)
            } catch {
                cont.resume(throwing: error)
            }
        }
    }

    private func fetchActiveIngredients(for medicationId: Int) throws -> [ActiveIngredient] {
        var activeIngredientsResult: [ActiveIngredient] = []
        let query = activeIngredients.filter(self.medicationId == Int64(medicationId))
        for ingredientRow in try dbConnection.prepare(query) {
            let ingredient = ActiveIngredient(
                id: Int(ingredientRow[id]),
                name: ingredientRow[name],
                quantity: ingredientRow[activeIngredientQuantity],
                unit: ActiveIngredient.Unit(rawValue: ingredientRow[unit]) ?? .mg
            )
            activeIngredientsResult.append(ingredient)
        }
        return activeIngredientsResult
    }

    public func addMedication(name: String, activeIngredients: [ActiveIngredient]) async throws -> Medication {
        return try await withCheckedThrowingContinuation { cont in
            do {
                let insert = medications.insert(self.name <- name)
                let rowId = try dbConnection.run(insert)
                let medicationId = Int(rowId)
                
                for ingredient in activeIngredients {
                    try addActiveIngredient(for: medicationId, ingredient: ingredient)
                }
                
                let medication = Medication(
                    id: medicationId,
                    name: name,
                    activeIngredients: activeIngredients
                )
                
                cont.resume(returning: medication)
            } catch {
                cont.resume(throwing: error)
            }
        }
    }

    private func addActiveIngredient(for medicationId: Int, ingredient: ActiveIngredient) throws {
        let insert = activeIngredients.insert(
            self.name <- ingredient.name,
            self.activeIngredientQuantity <- ingredient.quantity,
            self.unit <- ingredient.unit.rawValue,
            self.medicationId <- Int64(medicationId)
        )
        try dbConnection.run(insert)
    }

    public func updateMedication(_ medication: Medication) async throws -> Void {
        return try await withCheckedThrowingContinuation { cont in
            do {
                let dbMedication = medications.filter(self.id == Int64(medication.id))
                let update = dbMedication.update(name <- medication.name)
                try dbConnection.run(update)
                
                try deleteActiveIngredients(for: medication.id)
                
                for ingredient in medication.activeIngredients {
                    try addActiveIngredient(for: medication.id, ingredient: ingredient)
                }
                
                cont.resume(returning: ())
            } catch {
                cont.resume(throwing: error)
            }
        }
    }

    private func deleteActiveIngredients(for medicationId: Int) throws {
        let query = activeIngredients.filter(self.medicationId == Int64(medicationId))
        try dbConnection.run(query.delete())
    }

    public func deleteMedication(with id: Int) async throws -> Void {
        return try await withCheckedThrowingContinuation { cont in
            do {
                let deleteMedication = medications.filter(self.id == Int64(id))
                try dbConnection.transaction {
                    let deleteActiveIngredients = activeIngredients.filter(self.medicationId == Int64(id))
                    try dbConnection.run(deleteActiveIngredients.delete())
                    try dbConnection.run(deleteMedication.delete())
                }
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
                let exists = try dbConnection.scalar(intakes.exists)
                if !exists {
                    createEcgTable()
                }
                addEcgData()
            } catch {
                createEcgTable()
                addEcgData()
            }
            func addEcgData() {
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
    }
    
    
    public func fetchRecentEcgData(seconds: Int) async throws -> [EcgDTO] {
        return try await withCheckedThrowingContinuation { cont in
            do {
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
    
    public func deleteAllEcgEvents() async throws -> Void {
        return try await withCheckedThrowingContinuation { cont in
            do {
                let deleteAll = ecgEvents.delete()
                try dbConnection.run(deleteAll)
                cont.resume(returning: ())
            } catch {
                cont.resume(throwing: error)
            }
        }
    }
}
