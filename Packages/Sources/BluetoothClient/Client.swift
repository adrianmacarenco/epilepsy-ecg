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
import Model

public struct BluetoothClient {
    public var getBatteryLevel: () async -> Int
    // TODO: Modify scanDevices and stopScanningDevices to async
    public var scanDevices: () -> ()
    public var stopScanningDevices: () -> ()
    public var getDevice:(DeviceNameSerial) -> DeviceWrapper?
    public var discoveredDevicesStream: () -> AsyncStream<DeviceWrapper>
    public var connectToDevice: (DeviceWrapper) async throws -> DeviceWrapper
    public var disconnectDevice: (DeviceWrapper) async throws -> DeviceWrapper
    public var subscribeToEcg: (DeviceWrapper) -> ()
    public var ecgPacketsStream: () -> AsyncStream<MovesenseEcg>
    
    public init(
        getBatteryLevel: @escaping () -> Int,
        scanDevices: @escaping () -> (),
        stopScanningDevices: @escaping () -> (),
        getDevice: @escaping (DeviceNameSerial) -> (DeviceWrapper?),
        discoveredDevicesStream: @escaping () -> AsyncStream<DeviceWrapper>,
        connectToDevice: @escaping (DeviceWrapper) async throws -> DeviceWrapper,
        disconnectDevice: @escaping (DeviceWrapper) async throws -> DeviceWrapper,
        subscribeToEcg: @escaping (DeviceWrapper) -> (),
        ecgPacketsStream: @escaping () -> AsyncStream<MovesenseEcg>
    ) {
        self.getBatteryLevel = getBatteryLevel
        self.scanDevices = scanDevices
        self.getDevice = getDevice
        self.stopScanningDevices = stopScanningDevices
        self.discoveredDevicesStream = discoveredDevicesStream
        self.connectToDevice = connectToDevice
        self.disconnectDevice = disconnectDevice
        self.subscribeToEcg = subscribeToEcg
        self.ecgPacketsStream = ecgPacketsStream
    }
}

extension BluetoothClient: DependencyKey {
    public static var liveValue: BluetoothClient {
        let bluetoothManager = BluetoothManager()
        
        return .init(
            getBatteryLevel: { return 5 },
            scanDevices: bluetoothManager.scanAvailableDevices,
            stopScanningDevices: bluetoothManager.stopScanningDevices,
            getDevice: { bluetoothManager.getDevice(with: $0)},
            discoveredDevicesStream: { bluetoothManager.discoveredDevicesStream },
            connectToDevice: { try await bluetoothManager.connectToDevice($0) },
            disconnectDevice: { try await bluetoothManager.disconnectDevice($0) },
            subscribeToEcg: bluetoothManager.subscribeToEcg(_:),
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
