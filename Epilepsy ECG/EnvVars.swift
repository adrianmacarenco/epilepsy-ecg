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
    var studyId: String
    var carpUserName: String
    var carpPassword: String
}

extension EnvVars: DependencyKey {
    public static var liveValue: EnvVars {
        .init(
            persistenceKeyPrefix: Bundle.main.bundleIdentifier!,
            baseUrl: URL(string: "https://cans.cachet.dk")!,
            studyId: "5300a9b7-204b-4c6b-8757-fec603507200",
            carpUserName: "adrian.macarenco@gmail.com",
            carpPassword: "Setanta1234"
        )
    }
}

extension DependencyValues {
    public var envVars: EnvVars {
       get { self[EnvVars.self] }
       set { self[EnvVars.self] = newValue }
     }
}
