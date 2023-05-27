//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 19/05/2023.
//

import Foundation

public struct Medication {
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

public struct ActiveIngredient {
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
    
    public enum Unit: String, CaseIterable {
        case mg = "mg"
        case g = "g"
    }
}
