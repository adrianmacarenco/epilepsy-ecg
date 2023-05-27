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
    public var user: FileClient<User>
    public var deviceNameSerial: FileClient<DeviceNameSerial>
    public var deviceConfigurations: FileClient<[DeviceConfiguration]>
    public var ecgConfiguration: FileClient<EcgConfiguration>
    public var medications: FileClient<[Medication]>
    public var medicationIntakes: FileClient<[MedicationIntake]>
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
