//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 04/05/2023.
//

import Foundation
import Model

extension PersistenceClient {
    public static let noop = Self(
        deviceNameSerial: .noop,
        deviceConfigurations: .noop
    )

    public static let failing = Self(
        deviceNameSerial: .failing,
        deviceConfigurations: .failing
    )

    public static let mock = Self(
        deviceNameSerial: .init(load: { .init(localName: "MockedName", serial: "MockedSerial") }, save: { _ in }),
        deviceConfigurations: .init(load: { .init()}, save: { _ in })
    )
}
