//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 18/03/2023.
//

import Foundation
import MovesenseApi

// Used as a wrapper, we need Identifiable conformance
public struct Device {
    let movesenseDevice: MovesenseDevice
}

extension Device: Identifiable {
    public var id: UUID { movesenseDevice.uuid }
}
