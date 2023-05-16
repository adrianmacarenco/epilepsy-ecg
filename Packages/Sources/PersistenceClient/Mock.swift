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
        deviceConfigurations: .noop,
        ecgConfiguration: .noop
    )

    public static let failing = Self(
        deviceNameSerial: .failing,
        deviceConfigurations: .failing,
        ecgConfiguration: .failing
    )

    public static let mock = Self(
        deviceNameSerial: .init(load: { .init(localName: "MockedName", serial: "MockedSerial") }, save: { _ in }),
        deviceConfigurations: .init(load: { .init()}, save: { _ in }),
        ecgConfiguration: .init(
            load: { .init(
                viewConfiguration: .init(
                    lineWidth: 0.0,
                    chartColor: .black,
                    timeInterval: 0.0
                ),
                frequency: 0)},
            save: { _ in})
    )
}
