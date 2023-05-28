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
    case dataNotFound(message: String)
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
    
    public func getUser(with userId: String) async throws -> User {
        return try await withCheckedThrowingContinuation { cont in
            do {
                let query = users.filter(self.userId == userId)
                guard let userRow = try dbConnection.pluck(query) else {
                    cont.resume(throwing: DatabaseError.dataNotFound(message: "User could not be found"))
                    return
                }
                let user = User(
                    id: userRow[self.userId],
                    fullName: userRow[self.fullName],
                    birthday: userRow[self.birthday],
                    gender: userRow[self.gender],
                    weight: userRow[self.weight],
                    height: userRow[self.height],
                    diagnosis: userRow[self.diagnosis]
                )
                cont.resume(returning: user)
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
                try printAllMedications()
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
                var localIngredients: [ActiveIngredient] = []
                
                for ingredient in activeIngredients {
                    let addedIngredient = try addActiveIngredient(for: medicationId, ingredient: ingredient)
                    localIngredients.append(addedIngredient)
                }
                
                let medication = Medication(
                    id: medicationId,
                    name: name,
                    activeIngredients: localIngredients
                )
                
                try printAllMedications()
                try printAllActiveIngredients()

                cont.resume(returning: medication)
            } catch {
                cont.resume(throwing: error)
            }
        }
    }

    private func addActiveIngredient(for medicationId: Int, ingredient: ActiveIngredient) throws -> ActiveIngredient {
        let insert = activeIngredients.insert(
            self.name <- ingredient.name,
            self.activeIngredientQuantity <- ingredient.quantity,
            self.unit <- ingredient.unit.rawValue,
            self.medicationId <- Int64(medicationId)
        )
        let rowId  = try dbConnection.run(insert)
        return .init(id: Int(rowId), name: ingredient.name, quantity: ingredient.quantity, unit: ingredient.unit)
    }

    public func updateMedication(_ medication: Medication) async throws -> Void {
        return try await withCheckedThrowingContinuation { cont in
            do {
                let dbMedication = medications.filter(self.id == Int64(medication.id))
                let update = dbMedication.update(name <- medication.name)
                try dbConnection.run(update)
                
                try deleteActiveIngredients(for: medication.id)
                
                for ingredient in medication.activeIngredients {
                   _ = try addActiveIngredient(for: medication.id, ingredient: ingredient)
                }
                
                try printAllMedications()
                try printAllActiveIngredients()
                
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
                for intakeRow in try dbConnection.prepare(intakes.join(medications, on: medications[id] == intakes[medicationId])) {
                    let medication = Medication(
                        id: Int(intakeRow[medications[id]]),
                        name: intakeRow[medications[name]],
                        activeIngredients: []
                    )
                    intakesResult.append(MedicationIntake(
                        id: Int(intakeRow[intakes[id]]),
                        timestamp: intakeRow[intakes[timestamp]],
                        pillQuantity: intakeRow[intakes[pillQuantity]],
                        medication: medication
                    ))
                }
                cont.resume(returning: intakesResult)
            } catch {
                cont.resume(throwing: error)
            }
        }
    }
    
    public func fetchDailyIntakes() async throws -> [MedicationIntake] {
        let currentDate = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: currentDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return try await withCheckedThrowingContinuation { cont in
            do {
                var intakesResult: [MedicationIntake] = []
                
                let query = intakes
                    .join(medications, on: medications[id] == intakes[medicationId])
                    .filter(timestamp >= startOfDay && timestamp < endOfDay)
                
                for intakeRow in try dbConnection.prepare(query) {
                    let medication = Medication(
                        id: Int(intakeRow[medications[id]]),
                        name: intakeRow[medications[name]],
                        activeIngredients: []
                    )
                    intakesResult.append(MedicationIntake(
                        id: Int(intakeRow[intakes[id]]),
                        timestamp: intakeRow[intakes[timestamp]],
                        pillQuantity: intakeRow[intakes[pillQuantity]],
                        medication: medication
                    ))
                }
                
                cont.resume(returning: intakesResult)
            } catch {
                cont.resume(throwing: error)
            }
        }
    }


    public func addIntake(timestamp: Date, pillQuantity: Double, medication: Medication) async throws -> MedicationIntake {
        return try await withCheckedThrowingContinuation { cont in
            do {
                let insert = intakes.insert(self.timestamp <- timestamp, self.pillQuantity <- pillQuantity, self.medicationId <- Int64(medication.id))
                let rowId = try dbConnection.run(insert)
                let intake = MedicationIntake(
                    id: Int(rowId),
                    timestamp: timestamp,
                    pillQuantity: pillQuantity,
                    medication: medication
                )
                cont.resume(returning: intake)
            } catch {
                cont.resume(throwing: error)
            }
        }
    }

    public func updateIntake(_ intake: MedicationIntake) async throws -> Void {
        return try await withCheckedThrowingContinuation { cont in
            do {
                let update = intakes.filter(id == Int64(intake.id)).update(
                    timestamp <- intake.timestamp,
                    pillQuantity <- intake.pillQuantity,
                    medicationId <- Int64(intake.medication.id)
                )
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
    
    // Print all rows from the medications table
    func printAllMedications() throws {
        let query = medications.select(*)
        
        for row in try dbConnection.prepare(query) {
            let id = row[id]
            let name = row[name]
            
            print("Medication ID: \(id), Name: \(name)")
        }
    }

    // Print all rows from the activeIngredients table
    func printAllActiveIngredients() throws {
        let query = activeIngredients.select(*)
        
        for row in try dbConnection.prepare(query) {
            let id = row[id]
            let name = row[name]
            let quantity = row[activeIngredientQuantity]
            let unit = row[unit]
            let medicationId = row[medicationId]
            
            print("Active Ingredient ID: \(id), Name: \(name), Quantity: \(quantity), Unit: \(unit), Medication ID: \(medicationId)")
        }
    }

    // Print all rows from the intakes table
    func printAllIntakes() throws {
        let query = intakes.select(*)
        
        for row in try dbConnection.prepare(query) {
            let id = row[id]
            let timestamp = row[timestamp]
            let pillQuantity = row[pillQuantity]
            let medicationId = row[medicationId]
            
            print("Intake ID: \(id), Timestamp: \(timestamp), Pill Quantity: \(pillQuantity), Medication ID: \(medicationId)")
        }
    }

}
