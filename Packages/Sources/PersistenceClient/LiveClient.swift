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
            user: .live(key: keyPrefix + ".savedUser"),
            deviceNameSerial: .live(key: keyPrefix + ".savedConnectedNameSerialDevice"),
            deviceConfigurations: .live(key: keyPrefix + ".savedConnectedDeviceConfigurations"),
            ecgConfiguration: .live(key: keyPrefix + ".savedEcgViewConfiguration"),
            medications: .live(key: keyPrefix + ".savedMedications"),
            medicationIntakes: .live(key: keyPrefix + ".savedMedicationIntakes"),
            apiTokenWrapper: .live(key: keyPrefix + ".apiTokenWrapper")
        )
    }
}
