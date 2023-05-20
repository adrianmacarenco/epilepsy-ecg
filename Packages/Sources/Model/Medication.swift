//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 19/05/2023.
//

import Foundation

public struct Medication {
    public let id: Int
    public let name: String
    public let activeIngredientQuantity: Double
    
    public init(
        id: Int,
        name: String,
        activeIngredientQuantity: Double
    ) {
        self.id = id
        self.name = name
        self.activeIngredientQuantity = activeIngredientQuantity
    }
}
