//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 04/05/2023.
//

import Foundation

extension PersistenceClient {
    public static func live(keyPrefix: String) -> Self {
        .init(
            deviceNameSerial:.live(key: keyPrefix + ".savedConnectedNameSerialDevice"),
            deviceConfigurations: .live(key: keyPrefix + ".savedConnectedDeviceConfigurations")
        )
    }
}
