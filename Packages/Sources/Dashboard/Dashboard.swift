//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 01/05/2023.
//

import Foundation
import SwiftUI
import StylePackage
import AddDevice
import SwiftUINavigation
import Dependencies
import PersistenceClient
import BluetoothClient
import IdentifiedCollections
import Model
import Charts

public class DashboardViewModel: ObservableObject {
    enum Destination: Equatable {
        case addDevice(AddDeviceViewModel)
    }
    
    @Published var route: Destination?
    @Published var previousDevices: IdentifiedArrayOf<DeviceNameSerial> = []

    @Dependency(\.persistenceClient) var persistenceClient
    @Dependency(\.bluetoothClient) var bluetoothClient

    public init() {}
    
    func onAppear() {
//        if let savedDeviceNameSerial = persistenceClient.deviceNameSerial.load(),
//           let foundDevice = bluetoothClient.getDevice(savedDeviceNameSerial) {
//            print("🔍 \(foundDevice)")
//        }
        if let savedDeviceNameSerial = persistenceClient.deviceNameSerial.load() {
            //Display the previous device here
            previousDevices.append(savedDeviceNameSerial)
            bluetoothClient.scanDevices()
        }
        
    }
    
    func addDeviceButtonTapped() {
        let addDeviceViewModel = withDependencies(from: self) {
            AddDeviceViewModel()
        }
        route = .addDevice(addDeviceViewModel)
    }
    
    func cancelAddDeviceTapped() {
        route = nil
    }
    
    func connectButtonTapped(deviceNameSerial: DeviceNameSerial) {
        
    }
}

public struct DashboardView: View {
    @ObservedObject var vm: DashboardViewModel
    
    public init(
        vm: DashboardViewModel
    ) {
        self.vm = vm
    }
    
    public var body: some View {
        VStack {
            ForEach(vm.previousDevices) { deviceSerialName in
                VStack {
                    Text(deviceSerialName.localName)
                        .foregroundColor(.black)
                    HStack {
                        Button("Connect", action: {
                            vm.connectButtonTapped(deviceNameSerial: deviceSerialName)
                        })
                        Button("Disconnect", action: {
                            vm.connectButtonTapped(deviceNameSerial: deviceSerialName)
                        })
                    }
                }
            }
            Spacer()
            Button("Add my device", action: vm.addDeviceButtonTapped)
                .buttonStyle(MyButtonStyle.init(style: .primary))
                .padding(.horizontal, 16)
                .padding(.bottom, 58)
            Divider()
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
        .background(Color.background)
        .onAppear(perform: vm.onAppear)
        .sheet(
            unwrapping: $vm.route,
            case: /DashboardViewModel.Destination.addDevice
        ) { $scanDevicesVm in
            NavigationStack {
                AddDeviceView(viewModel: scanDevicesVm)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarBackground(.white, for: .navigationBar)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(action: vm.cancelAddDeviceTapped) {
                                Text("Cancel")
                            }
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("Add device")
                                .font(.title1)
                                .foregroundColor(.black)
                        }
                    }
            }
            
        }
    }
}


