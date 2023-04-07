//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 06/04/2023.
//

import Foundation
import CoreBluetooth
import Model

public class BluetoothManager: NSObject {
    typealias PeripheralContinuation = CheckedContinuation<CBPeripheral, Error>

    private var centralManager: CBCentralManager!
    private var connectingPeripheral: CBPeripheral?
    
    private var connectingContinuation: PeripheralContinuation?
    
    var peripheralContinuation: AsyncStream<CBPeripheral>.Continuation!
    var ecgPacketContinuation: AsyncStream<ECGPacket>.Continuation!

    lazy var peripheralStream: AsyncStream<CBPeripheral> = {
        .init { cont in
        peripheralContinuation = cont
        }}()
    
    public lazy var ecgPacketsStream: AsyncStream<ECGPacket> = {
        .init { cont in
            ecgPacketContinuation = cont
        }}()
    
    public override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
}

//MARK: Public Interface
public extension BluetoothManager {
    func scanAvailableDevices() -> AsyncStream<CBPeripheral> {
        centralManager.scanForPeripherals(withServices: nil)
        return peripheralStream
    }
    
    func connectToPeripheral(_ peripheral: CBPeripheral) async throws -> CBPeripheral {
        return try await withCheckedThrowingContinuation { cont in
            connectingContinuation = cont
            centralManager.connect(peripheral)
            connectingPeripheral = peripheral
        }
    }
}

//MARK: CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(
        _ central: CBCentralManager
    ) {
        if central.state == .poweredOn {
            print("🔌 powered on")
//            centralManager.scanForPeripherals(withServices: nil)
        }
    }
    
    public func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String : Any], rssi RSSI: NSNumber
    ) {
        peripheralContinuation.yield(peripheral)
    }
    
    public func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        if peripheral == connectingPeripheral {
            connectingContinuation?.resume(returning: peripheral)
        } else {
            connectingContinuation?.resume(throwing: BluetoothError.failedToConnectToGivenDevice)
        }
    }
    
    public func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        if let error = error {
            connectingContinuation?.resume(throwing: error)
        } else {
            connectingContinuation?.resume(throwing: BluetoothError.failedToConnect)
        }
    }
}

extension BluetoothManager: CBPeripheralDelegate {
    public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverIncludedServicesFor service: CBService,
        error: Error?
    ) {
        
    }
    
    public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        
    }
}

enum BluetoothError: Error {
    case  failedToConnect
    case failedToConnectToGivenDevice
}
