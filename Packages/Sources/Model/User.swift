//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 21/05/2023.
//

import Foundation

public struct User: Codable {
    public let id: String
    public var fullName: String?
    public var birthday: Date?
    public var gender: String?
    public var weight: Double?
    public var height: Double?
    public var diagnosis: String?
    
    public init(
        id: String,
        fullName: String?,
        birthday: Date?,
        gender: String?,
        weight: Double?,
        height: Double?,
        diagnosis: String?
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
