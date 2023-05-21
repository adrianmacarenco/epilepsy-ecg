//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 21/05/2023.
//

import Foundation

public struct User {
    public let id: Int
    public let fullName: String
    public let birthday: Date
    public let gender: String
    public let weight: Double
    public let height: Double
    public let diagnosis: String
    
    public init(
        id: Int,
        fullName: String,
        birthday: Date,
        gender: String,
        weight: Double,
        height: Double,
        diagnosis: String
    ) {
        self.id = id
        self.fullName = fullName
        self.birthday = birthday
        self.gender = gender
        self.weight = weight
        self.height = height
        self.diagnosis = diagnosis
    }
}
