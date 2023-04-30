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

public class BluetoothManager: NSObject {
    
    private var connectingContinuation: CheckedContinuation<MovesenseDevice, Error>!
    
    var discoveredDeviceContinuation: AsyncStream<MovesenseDevice>.Continuation!
    var peripheralContinuation: AsyncStream<CBPeripheral>.Continuation!
    var ecgPacketContinuation: AsyncStream<MovesenseEcg>.Continuation!

    public lazy var peripheralStream: AsyncStream<CBPeripheral> = {
        .init { cont in
        peripheralContinuation = cont
        }}()
    
    public lazy var discoveredDevicesStream: AsyncStream<MovesenseDevice> = {
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
    
    func connectToPeripheral(_ device: MovesenseDevice) async throws -> MovesenseDevice {
        Movesense.api.connectDevice(device)
        return try await withCheckedThrowingContinuation { cont in
            connectingContinuation = cont
        }
    }
}

//MARK: MoverSenseAPI
extension BluetoothManager: Observer {
    public func handleEvent(_ event: ObserverEvent) {
        
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
        default: print(event)
        }
    }
    
    private func didReceiveApiEvent(_ event: MovesenseObserverEventDevice) {
        switch event {
        case .deviceConnecting(let device):
            print(device)
            
        case .deviceConnected(let device):
            connectingContinuation.resume(returning: device)
            
        case .deviceDisconnected(let device):
            print(device)
            
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
        discoveredDeviceContinuation.yield(device)
    }
    
    private func deviceConnected(_ device: MovesenseDevice) {
        
    }
}


enum BluetoothError: Error {
    case  failedToConnect
    case failedToConnectToGivenDevice
}
