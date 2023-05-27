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
        user: .noop,
        deviceNameSerial: .noop,
        deviceConfigurations: .noop,
        ecgConfiguration: .noop,
        medications: .noop,
        medicationIntakes: .noop
    )

    public static let failing = Self(
        user: .noop,
        deviceNameSerial: .failing,
        deviceConfigurations: .failing,
        ecgConfiguration: .failing,
        medications: .failing,
        medicationIntakes: .failing
    )

    public static let mock = Self(
        user: .init(
            load: { .init(id: "-1", fullName: "", birthday: Date(), gender: "", weight: 0.0, height: 0.0, diagnosis: nil) },
            save: { _ in }
        ),
        deviceNameSerial: .init(
            load: { .init(localName: "MockedName", serial: "MockedSerial") },
            save: { _ in }
        ),
        deviceConfigurations: .init(
            load: { .init()},
            save: { _ in }
        ),
        ecgConfiguration: .init(
            load: { .init(
                viewConfiguration: .init(
                    lineWidth: 0.0,
                    chartColor: .black,
                    timeInterval: 0.0
                ),
                frequency: 0)},
            save: { _ in}
        ),
        medications: .init(
            load: { [] },
            save: { _ in }
        ),
        medicationIntakes: .init(
            load: { [] },
            save: { _ in }
        )
    )
}
