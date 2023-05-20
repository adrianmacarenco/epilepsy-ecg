//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 19/05/2023.
//

import Foundation
import MovesenseApi

public struct EcgDTO {
    public let timestamp: Date
    public let stringData: String
    
    public init(
        timestamp: Date,
        stringData: String
    ) {
        self.timestamp = timestamp
        self.stringData = stringData
    }
}
