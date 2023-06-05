//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 06/06/2023.
//

import Foundation

extension User {
    public static var mock: User = .init(id: "", fullName: "", birthday: Date(), gender: "", weight: 0, height: 0, diagnosis: nil)
}

extension Medication {
    public static var mock: Medication = .init(id: 0, name: "", activeIngredients: [])
}

extension MedicationIntake {
    public static var mock: MedicationIntake = .init(id: 0, timestamp: Date(), pillQuantity: 0, medication: .mock)
}
