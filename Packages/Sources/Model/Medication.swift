//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 19/05/2023.
//

import Foundation

public struct Medication: Codable, Equatable {
    public static func == (lhs: Medication, rhs: Medication) -> Bool {
        rhs.id == lhs.id && rhs.name == lhs.name && rhs.activeIngredients == lhs.activeIngredients
    }
    
    public var id: Int
    public var name: String
    public var activeIngredients: [ActiveIngredient]
    
    public init(
        id: Int,
        name: String,
        activeIngredients: [ActiveIngredient]
    ) {
        self.id = id
        self.name = name
        self.activeIngredients = activeIngredients
    }
}

public struct ActiveIngredient: Codable, Equatable {
    public var id: Int
    public var name: String
    public var quantity: Double
    public var unit: Unit
    
    public init(
        id: Int,
        name: String,
        quantity: Double,
        unit: Unit
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
    }
    
    public enum Unit: String, CaseIterable, Codable {
        case mg = "mg"
        case g = "g"
    }
}
