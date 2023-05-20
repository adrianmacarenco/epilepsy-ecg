//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 19/05/2023.
//

import Foundation

public struct MedicationIntake {
    public let id: Int
    public let timestamp: Date
    public let pillQuantity: Double
    public let medicationId: Int
    
    public init(
        id: Int,
        timestamp: Date,
        pillQuantity: Double,
        medicationId: Int
    ) {
        self.id = id
        self.timestamp = timestamp
        self.pillQuantity = pillQuantity
        self.medicationId = medicationId
    }
}
