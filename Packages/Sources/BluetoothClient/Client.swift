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
import MovesenseApi

public struct BluetoothClient {
    public var getBatteryLevel: () async -> Int
    public var scanDevices: () -> ()
    public var discoveredDevicesStream: () -> AsyncStream<MovesenseDevice>
    public var discoveredPeripheralsStream: () -> AsyncStream<CBPeripheral>
    public var connectToPeripheral: (MovesenseDevice) async throws -> MovesenseDevice
    public var ecgPacketsStream: () -> AsyncStream<MovesenseEcg>
    
    public init(
        getBatteryLevel: @escaping () -> Int,
        scanDevices: @escaping () -> (),
        discoveredDevicesStream: @escaping () -> AsyncStream<MovesenseDevice>,
        discoveredPeripheralsStream: @escaping () -> AsyncStream<CBPeripheral>,
        connectToPeripheral: @escaping (MovesenseDevice) async throws -> MovesenseDevice,
        ecgPacketsStream: @escaping () -> AsyncStream<MovesenseEcg>
    ) {
        self.getBatteryLevel = getBatteryLevel
        self.scanDevices = scanDevices
        self.discoveredDevicesStream = discoveredDevicesStream
        self.discoveredPeripheralsStream = discoveredPeripheralsStream
        self.connectToPeripheral = connectToPeripheral
        self.ecgPacketsStream = ecgPacketsStream
    }
}

extension BluetoothClient: DependencyKey {
    public static var liveValue: BluetoothClient {
        let bluetoothManager = BluetoothManager()
        
        return .init(
            getBatteryLevel: { return 5 },
            scanDevices: { bluetoothManager.scanAvailableDevices() },
            discoveredDevicesStream: { bluetoothManager.discoveredDevicesStream },
            discoveredPeripheralsStream: { bluetoothManager.peripheralStream },
            connectToPeripheral: { try await bluetoothManager.connectToPeripheral($0) },
            ecgPacketsStream: { bluetoothManager.ecgPacketsStream }
        )
    }
}


public extension DependencyValues {
    var bluetoothClient: BluetoothClient {
        get { self[BluetoothClient.self] }
        set { self[BluetoothClient.self] = newValue }
    }
}
