//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 18/03/2023.
//

import Foundation

public struct ECGPacket {
    let signature: String
    let flag: UInt8
    let packetNumber: UInt32
    let ecgData: [Int16]
    let accelerometerData: (x: Int16, y: Int16, z: Int16)
    let marker: UInt16
    let rrInterval: Int16?
    let temperature: UInt16?
    let batteryVoltage: UInt16?
    let timestamp: UInt32?
    let pacemakerEvents: [PacemakerEvent]
    let reserved: [UInt8]
    let padding: [UInt8]?
    let checksum: UInt16
}

public extension ECGPacket {
    init?(data: Data) {
        guard data.count >= 25 else { return nil }
        
        signature = String(bytes: data[0..<3], encoding: .ascii) ?? ""
        guard signature == "MEP" else { return nil }
        
        flag = data[3]
        packetNumber = data[4...7].withUnsafeBytes { $0.load(as: UInt32.self) }.byteSwapped
        
        // ECG data
        ecgData = [
            Int16(bigEndian: data.subdata(in: 8..<10).withUnsafeBytes { $0.load(as: Int16.self) }),
            Int16(bigEndian: data.subdata(in: 10..<12).withUnsafeBytes { $0.load(as: Int16.self) }),
        ]
        // Accelerometer data
        let accelX = data[10...11].withUnsafeBytes { $0.load(as: Int16.self) }.bigEndian
        let accelY = data[12...13].withUnsafeBytes { $0.load(as: Int16.self) }.bigEndian
        let accelZ = data[14...15].withUnsafeBytes { $0.load(as: Int16.self) }.bigEndian
        accelerometerData = (accelX, accelY, accelZ)
        
        // Marker data
        marker = data[16...17].withUnsafeBytes { $0.load(as: UInt16.self) }.bigEndian
        
        // RR-interval
        if flag & 1 == 1 {
            rrInterval = Int16(bigEndian: data.subdata(in: 20..<22).withUnsafeBytes { $0.load(as: Int16.self) })
        } else {
            rrInterval = nil
        }
        
        // Assuming the temperature, batteryVoltage, and timestamp are always available
        temperature = UInt16(bigEndian: data.subdata(in: 22..<24).withUnsafeBytes { $0.load(as: UInt16.self) })
        batteryVoltage = UInt16(bigEndian: data.subdata(in: 24..<26).withUnsafeBytes { $0.load(as: UInt16.self) })
        timestamp = UInt32(bigEndian: data.subdata(in: 26..<30).withUnsafeBytes { $0.load(as: UInt32.self) })
        
        // Assuming the pacemakerEvents are not always available
        if data.count > 30 {
            pacemakerEvents = [
                PacemakerEvent(data: data.subdata(in: 30..<32)),
                PacemakerEvent(data: data.subdata(in: 32..<34)),
            ]
        } else {
            pacemakerEvents = []
        }
        
        let reservedStartIndex = 30
        let reservedEndIndex = reservedStartIndex + 5
        reserved = Array(data[reservedStartIndex..<reservedEndIndex])
        
        let paddingStartIndex = reservedEndIndex
        let paddingEndIndex = paddingStartIndex + 1
        padding = Array(data[paddingStartIndex..<paddingEndIndex])
        
        checksum = UInt16(bigEndian: data.subdata(in: data.count - 2..<data.count).withUnsafeBytes { $0.load(as: UInt16.self) })
        
    }
}

struct PacemakerEvent {
    let isDetected: Bool
    let timestamp: UInt16
    
    init(data: Data) {
        isDetected = (data[0] & 0x80) != 0
        timestamp = UInt16(data[0] & 0x7F) | UInt16(data[1]) << 7
    }
}
