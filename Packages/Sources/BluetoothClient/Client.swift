//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 05/03/2023.
//

import Foundation
import CoreBluetooth
import Dependencies
import BluetoothManager
import Model

public struct BluetoothClient {
    public var getBatteryLevel: () async -> Int
    public var scanForDevices: () -> AsyncStream<CBPeripheral>
    public var connectToPeripheral: (CBPeripheral) async throws -> CBPeripheral
    public var ecgPacketsStream: () -> AsyncStream<ECGPacket>
    
    public init(
        getBatteryLevel: @escaping () -> Int,
        scanForDevices: @escaping () -> AsyncStream<CBPeripheral>,
        connectToPeripheral: @escaping (CBPeripheral) async throws -> CBPeripheral,
        ecgPacketsStream: @escaping () -> AsyncStream<ECGPacket>
    ) {
        self.getBatteryLevel = getBatteryLevel
        self.scanForDevices = scanForDevices
        self.connectToPeripheral = connectToPeripheral
        self.ecgPacketsStream = ecgPacketsStream
    }
}

extension BluetoothClient: DependencyKey {
    public static var liveValue: BluetoothClient {
        let bluetoothManager = BluetoothManager()
        
        return .init(
            getBatteryLevel: { return 5 },
            scanForDevices: { bluetoothManager.scanAvailableDevices() },
            connectToPeripheral: { try await bluetoothManager.connectToPeripheral($0) },
            ecgPacketsStream: { bluetoothManager.ecgPacketsStream }
        )
    }
}


extension DependencyValues {
    var bluetoothClient: BluetoothClient {
        get { self[BluetoothClient.self] }
        set { self[BluetoothClient.self] = newValue }
    }
}
