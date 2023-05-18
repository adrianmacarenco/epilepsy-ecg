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
    public var getDeviceBattery: (DeviceWrapper) async throws -> Int
    // TODO: Modify scanDevices and stopScanningDevices to async
    public var scanDevices: () -> ()
    public var stopScanningDevices: () -> ()
    public var getDevice:(DeviceNameSerial) -> DeviceWrapper?
    public var getDiscoveredDevices: () -> [DeviceWrapper]
    public var discoveredDevicesStream: () -> AsyncStream<DeviceWrapper>
    public var connectToDevice: (DeviceWrapper) async throws -> DeviceWrapper
    public var disconnectDevice: (DeviceWrapper) async throws -> DeviceWrapper
    public var subscribeToEcg: (DeviceWrapper, Int) -> ()
    public var dashboardEcgPacketsStream: () -> AsyncStream<MovesenseEcg>
    public var settingsEcgPacketsStream: () -> AsyncStream<MovesenseEcg>

    public init(
        getDeviceBattery: @escaping (DeviceWrapper) async throws -> Int,
        scanDevices: @escaping () -> (),
        stopScanningDevices: @escaping () -> (),
        getDevice: @escaping (DeviceNameSerial) -> (DeviceWrapper?),
        getDiscoveredDevices: @escaping() -> [DeviceWrapper] ,
        discoveredDevicesStream: @escaping () -> AsyncStream<DeviceWrapper>,
        connectToDevice: @escaping (DeviceWrapper) async throws -> DeviceWrapper,
        disconnectDevice: @escaping (DeviceWrapper) async throws -> DeviceWrapper,
        subscribeToEcg: @escaping (DeviceWrapper, Int) -> (),
        dashboardEcgPacketsStream: @escaping () -> AsyncStream<MovesenseEcg>,
        settingsEcgPacketsStream: @escaping () -> AsyncStream<MovesenseEcg>
    ) {
        self.getDeviceBattery = getDeviceBattery
        self.scanDevices = scanDevices
        self.getDevice = getDevice
        self.getDiscoveredDevices = getDiscoveredDevices
        self.stopScanningDevices = stopScanningDevices
        self.discoveredDevicesStream = discoveredDevicesStream
        self.connectToDevice = connectToDevice
        self.disconnectDevice = disconnectDevice
        self.subscribeToEcg = subscribeToEcg
        self.dashboardEcgPacketsStream = dashboardEcgPacketsStream
        self.settingsEcgPacketsStream = settingsEcgPacketsStream
    }
}

extension BluetoothClient: DependencyKey {
    public static var liveValue: BluetoothClient {
        let bluetoothManager = BluetoothManager()
        
        return .init(
            getDeviceBattery: { try await bluetoothManager.getDeviceBattery($0) },
            scanDevices: bluetoothManager.scanAvailableDevices,
            stopScanningDevices: bluetoothManager.stopScanningDevices,
            getDevice: bluetoothManager.getDevice(with: ),
            getDiscoveredDevices: bluetoothManager.getDiscoveredDevices,
            discoveredDevicesStream: { bluetoothManager.discoveredDevicesStream },
            connectToDevice: { try await bluetoothManager.connectToDevice($0) },
            disconnectDevice: { try await bluetoothManager.disconnectDevice($0) },
            subscribeToEcg: { device, freq in bluetoothManager.subscribeToEcg(device, frequency: freq) },
            dashboardEcgPacketsStream: { bluetoothManager.dashboardEcgPacketsStream },
            settingsEcgPacketsStream: { bluetoothManager.settingsEcgPacketsStream }
        )
    }
}


public extension DependencyValues {
    var bluetoothClient: BluetoothClient {
        get { self[BluetoothClient.self] }
        set { self[BluetoothClient.self] = newValue }
    }
}
