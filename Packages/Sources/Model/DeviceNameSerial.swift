//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 04/05/2023.
//

import Foundation

public struct DeviceNameSerial: Codable {
    public let localName: String
    public let serial: String
    
    public init(
        localName: String,
        serial: String
    ) {
        self.localName = localName
        self.serial = serial
    }
    
    public init(
        deviceWrapper: DeviceWrapper
    ) {
        self.localName = deviceWrapper.movesenseDevice.localName
        self.serial = deviceWrapper.movesenseDevice.serialNumber
    }
}

extension DeviceNameSerial: Identifiable {
    public var id: String {
        serial
    }
}
