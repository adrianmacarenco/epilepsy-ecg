//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 06/04/2023.
//

import Foundation
import CoreBluetooth
import Model
import MovesenseApi
import Dependencies

public class BluetoothManager: NSObject {
    
    private var connectingContinuation: CheckedContinuation<DeviceWrapper, Error>!
    private var disconnectingContinuation: CheckedContinuation<DeviceWrapper, Error>?

    var discoveredDeviceContinuation: AsyncStream<DeviceWrapper>.Continuation!
    var peripheralContinuation: AsyncStream<CBPeripheral>.Continuation!
    var ecgPacketContinuation: AsyncStream<MovesenseEcg>.Continuation!
    @Dependency (\.continuousClock) var clock

    public lazy var peripheralStream: AsyncStream<CBPeripheral> = {
        .init { cont in
        peripheralContinuation = cont
        }}()
    
    public lazy var discoveredDevicesStream: AsyncStream<DeviceWrapper> = {
        .init { cont in
            discoveredDeviceContinuation = cont
        }}()
    
    public lazy var ecgPacketsStream: AsyncStream<MovesenseEcg> = {
        .init { cont in
            ecgPacketContinuation = cont
        }}()
    
    public override init() {
        super.init()
        Movesense.api.addObserver(self)
    }
}

//MARK: Public Interface
public extension BluetoothManager {
    func scanAvailableDevices() {
        Movesense.api.startScan()
    }
    
    func stopScanningDevices() {
        Movesense.api.stopScan()
    }
    
    func getDevice(with nameSerial: DeviceNameSerial) -> DeviceWrapper? {
        if let savedDevice = Movesense.api.getDevices().first(where: {$0.serialNumber == nameSerial.serial}) {
            return .init(movesenseDevice: savedDevice)
        } else {
            return nil
        }
    }
    
    func connectToDevice(_ device: DeviceWrapper) async throws -> DeviceWrapper {
        Movesense.api.connectDevice(device.movesenseDevice)
        return try await withCheckedThrowingContinuation { cont in
            connectingContinuation = cont
        }
    }
    
    func disconnectDevice(_ device: DeviceWrapper) async throws -> DeviceWrapper {
        Task {
            do {
                try await clock.sleep(for: .milliseconds(100))
                Movesense.api.disconnectDevice(device.movesenseDevice)
            } catch {
                print(error.localizedDescription)
            }
        }
        return try await withCheckedThrowingContinuation { cont in
            disconnectingContinuation = cont
        }
    }
}

//MARK: MoverSenseAPI
extension BluetoothManager: Observer {
    public func handleEvent(_ event: ObserverEvent) {
        print(event)
        switch event {
        case let event as MovesenseObserverEventApi:
            didReceiveApiEvent(event)
        case let event as MovesenseObserverEventDevice:
            didReceiveApiEvent(event)
        case let event as MovesenseObserverEventOperation:
            didReceiveOperationEvent(event)
        default: return
        }
    }
    
    private func didReceiveApiEvent(_ event: MovesenseObserverEventApi) {
        switch event {
        case .apiDeviceDiscovered(let device):
            deviceDiscovered(device)
            
        case .apiDeviceConnected(let device):
            deviceConnected(device)
            
        case .apiDeviceDisconnected(let device):
            print("disconnected 😈")
            deviceDisconnected(device)
            
        default: print(event)
        }
    }
    
    private func didReceiveApiEvent(_ event: MovesenseObserverEventDevice) {
        switch event {
        case .deviceConnecting(let device):
            print(device)
            
        case .deviceConnected(let device):
//            connectingContinuation.resume(returning: device)
            print("REDUNDANT Connected callback, event: \(event)")
            
        case .deviceDisconnected(let device):
//            disconnectingContinuation.resume(returning: device)
            print("REDUNDANT Disconnected callback, event: \(event)")

            
        case .deviceOperationInitiated(let device, operation: _):
            print(device)

        case .deviceError(let device, let error):
            print(device)
            connectingContinuation.resume(throwing: error)

        }
    }
    
    private func didReceiveOperationEvent(_ event: MovesenseObserverEventOperation) {
        switch event {
        case .operationResponse:
            print(event)
            
        case .operationEvent(let opEvent):
            switch opEvent {
            case .acc(_, let acc):
                print(acc)
                
            case .ecg(_, let ecg):
                ecgPacketContinuation.yield(ecg)
                
            case .gyroscope(_, let gyro):
                print(gyro)
                
            case .heartRate(_, let heartRate):
                print(heartRate)
                
            }
        case .operationFinished:
            print(event)
            
        case .operationError(let error):
            print(error.localizedDescription)

        }
    }
    
    private func deviceDiscovered(_ device: MovesenseDevice) {
        discoveredDeviceContinuation.yield(DeviceWrapper(movesenseDevice: device))
    }
    
    private func deviceConnected(_ device: MovesenseDevice) {
        connectingContinuation.resume(returning: DeviceWrapper(movesenseDevice: device) )
    }
    
    private func deviceDisconnected(_ device: MovesenseDevice) {
        guard let disconnectingContinuation = disconnectingContinuation else { return }
        self.disconnectingContinuation = nil
        disconnectingContinuation.resume(returning: DeviceWrapper(movesenseDevice: device))
    }
}


enum BluetoothError: Error {
    case  failedToConnect
    case failedToConnectToGivenDevice
}
