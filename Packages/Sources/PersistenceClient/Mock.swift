//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 04/05/2023.
//

import Foundation

extension PersistenceClient {
    public static let noop = Self(
        deviceSerial: .noop
    )

    public static let failing = Self(
        deviceSerial: .failing
    )

    public static let mock = Self(
        deviceSerial: .init(load: { "mockedSerial" }, save: { _ in })
    )
}
