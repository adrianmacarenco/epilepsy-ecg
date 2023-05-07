//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 04/05/2023.
//

import Foundation
import Model
import Dependencies

/// Client used for storing data
public struct PersistenceClient {
    public var deviceNameSerial: FileClient<DeviceNameSerial>
}

extension PersistenceClient: TestDependencyKey {
    public static var testValue: Self {
        .failing
    }
}

public extension DependencyValues {
  var persistenceClient: PersistenceClient {
    get { self[PersistenceClient.self] }
    set { self[PersistenceClient.self] = newValue }
  }
}
