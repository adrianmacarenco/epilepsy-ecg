//
//  EnvVars.swift
//  Epilepsy-ECG
//
//  Created by Adrian Macarenco on 04/05/2023.
//

import Foundation
import Dependencies

public struct EnvVars {
    var persistenceKeyPrefix: String
    var baseUrl: URL
}

extension EnvVars: DependencyKey {
    public static var liveValue: EnvVars {
        .init(
            persistenceKeyPrefix: Bundle.main.bundleIdentifier!,
            baseUrl: URL(string: "https://cans.cachet.dk/dev")!
        )
    }
}

extension DependencyValues {
    public var envVars: EnvVars {
       get { self[EnvVars.self] }
       set { self[EnvVars.self] = newValue }
     }
}
