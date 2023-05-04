//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 18/03/2023.
//

import Foundation
import MovesenseApi

// Used as a wrapper, we need Identifiable conformance
public struct DeviceWrapper {
    public let movesenseDevice: MovesenseDevice
    
    public init(movesenseDevice: MovesenseDevice) {
        self.movesenseDevice = movesenseDevice        
    }
}

extension DeviceWrapper: Identifiable {
    public var id: UUID { movesenseDevice.uuid }
}
