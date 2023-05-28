//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 19/05/2023.
//

import Foundation

public struct MedicationIntake: Codable {
    public let id: Int
    public var timestamp: Date
    public var pillQuantity: Double
    public var medication: Medication
    
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
