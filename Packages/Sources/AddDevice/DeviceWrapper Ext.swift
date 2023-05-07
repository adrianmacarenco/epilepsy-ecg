//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 04/05/2023.
//

import Foundation
import Model

extension DeviceWrapper {
    public var nameSerial: DeviceNameSerial {
        return .init(deviceWrapper: self)
    }
}
