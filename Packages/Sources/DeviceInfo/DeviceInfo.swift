//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 29/05/2023.
//

import Foundation
import SwiftUI
import Combine
import Model
import MovesenseApi

public class DeviceInfoViewModel: ObservableObject, Equatable {
    public static func == (lhs: DeviceInfoViewModel, rhs: DeviceInfoViewModel) -> Bool {
        lhs.connectedDevice == rhs.connectedDevice
    }
    
    let connectedDevice: DeviceWrapper
    
    // MARK: - Public Interface
    
    public init(
        connectedDevice: DeviceWrapper
    ) {
        self.connectedDevice = connectedDevice
    }
    
}

public struct DeviceInfoView: View {
    @ObservedObject var vm: DeviceInfoViewModel
    
    public init(
        vm: DeviceInfoViewModel
    ) {
        self.vm = vm
    }
    
    public var body: some View {
        VStack {
            
        }
        .navigationTitle("Device information")
    }
}
