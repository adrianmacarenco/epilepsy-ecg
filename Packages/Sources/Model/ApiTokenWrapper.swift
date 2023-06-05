//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 03/06/2023.
//

import Foundation

public struct ApiTokenWrapper: Codable {
    public let accessToken: String
    public let expiresIn: Int
    public let refreshToken: String
    public let expiryDate: Date
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case expiryDate = "expiry_date"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try container.decode(String.self, forKey: .accessToken)
        expiresIn = try container.decode(Int.self, forKey: .expiresIn)
        refreshToken = try container.decode(String.self, forKey: .refreshToken)
        expiryDate = Date().addingTimeInterval(TimeInterval(expiresIn))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(accessToken, forKey: .accessToken)
        try container.encode(expiresIn, forKey: .expiresIn)
        try container.encode(refreshToken, forKey: .refreshToken)
        try container.encode(expiryDate, forKey: .expiryDate)
    }
    
    public init(
        accessToken: String,
        expiresIn: Int,
        refreshToken: String,
        expiryDate: Date
    ) {
        self.accessToken = accessToken
        self.expiresIn = expiresIn
        self.refreshToken = refreshToken
        self.expiryDate = expiryDate
    }
}
