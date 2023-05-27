//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 19/05/2023.
//

import Foundation

public struct MedicationIntake: Codable {
    public let id: Int
    public let timestamp: Date
    public let pillQuantity: Double
    public let medication: Medication
    
    public init(
        id: Int,
        timestamp: Date,
        pillQuantity: Double,
        medication: Medication
    ) {
        self.id = id
        self.timestamp = timestamp
        self.pillQuantity = pillQuantity
        self.medication = medication
    }
}
