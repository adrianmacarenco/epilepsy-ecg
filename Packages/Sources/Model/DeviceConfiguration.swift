//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 13/05/2023.
//

import Foundation

public struct DeviceConfiguration: Codable {
    let deviceSerial: String
    let ecgFrequency: Int
}
