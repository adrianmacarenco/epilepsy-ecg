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
import SwiftUICharts
import ECG
import ECG_Settings
import Combine

public class DashboardViewModel: ObservableObject {
    enum Destination: Equatable {
        case addDevice(AddDeviceViewModel)
        case ecgSettings(EcgSettingsViewModel)
    }
    
    @Published var route: Destination?
    @Published var previousDevices: IdentifiedArrayOf<DeviceNameSerial> = []
    @Published var discoveredDevices: IdentifiedArrayOf<DeviceWrapper> = []
    @Published var connectedDevices: IdentifiedArrayOf<DeviceWrapper> = []
    @Published var ecgViewModel: EcgViewModel = .init(data: [], ecgConfig: .defaultValue)
    
    var index = 0
    let previewInterval = 4
    var previewIntervalSamplesNr: Int {
        ecgViewModel.configuration.frequency * Int(previewInterval)
    }
    var hasSubscribedToEcg = false
    //    var ecgTask: Task<(), Never>?
    
    @Dependency(\.persistenceClient) var persistenceClient
    @Dependency(\.bluetoothClient) var bluetoothClient
    @Dependency (\.continuousClock) var clock
    
    
    public init() {}
    
    func onAppear() {
        
        if let ecgConfig = persistenceClient.ecgConfiguration.load() {
            ecgViewModel.configuration = ecgConfig
        }
        ecgViewModel.data = Array(repeating: 0.0, count: previewIntervalSamplesNr)
        if let savedDeviceNameSerial = persistenceClient.deviceNameSerial.load() {
            //Display the previous device here
            previousDevices.append(savedDeviceNameSerial)
            bluetoothClient.scanDevices()
        }
    }
    
    @MainActor
    func task() async {
        Task {
            for await device in bluetoothClient.discoveredDevicesStream() {
                discoveredDevices.append(device)
            }
        }
        Task {
            try await clock.sleep(for: .seconds(5))
            if discoveredDevices.isEmpty {
                let discoveredDevices = bluetoothClient.getDiscoveredDevices()
                print("👹 \(discoveredDevices)")
                discoveredDevices.forEach {
                    self.discoveredDevices.append($0)
                }
            }
            
        }
        subscribeToEcgStream()
        
    }
    
    func subscribeToEcgStream() {
        guard !hasSubscribedToEcg else { return }
        hasSubscribedToEcg = false
        Task { @MainActor in
            for await ecgData in bluetoothClient.dashboardEcgPacketsStream() {
                ecgData.samples.forEach { sample in
                    var finalSample = Double(sample)
                    if sample < ecgViewModel.configuration.viewConfiguration.minValue {
                        finalSample = Double(ecgViewModel.configuration.viewConfiguration.minValue)
                    } else if sample > ecgViewModel.configuration.viewConfiguration.maxValue {
                        finalSample = Double(ecgViewModel.configuration.viewConfiguration.maxValue)
                    }
                    self.ecgViewModel.data[index] =  finalSample
                    index += 1
                    if index ==  previewIntervalSamplesNr {
                        index = 0
                        ecgViewModel.data = Array(repeating: 0.0, count: previewIntervalSamplesNr)
                    }
                }
            }
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
        guard let deviceWrapper = discoveredDevices.first(where: { $0.movesenseDevice.serialNumber == deviceNameSerial.serial }) else {
            return
        }
        
        Task { @MainActor in
            let connectedDevice = try await bluetoothClient.connectToDevice(deviceWrapper)
            connectedDevices.append(connectedDevice)
            bluetoothClient.stopScanningDevices()
            try await clock.sleep(for: .seconds(3))
            bluetoothClient.subscribeToEcg(connectedDevice, ecgViewModel.configuration.frequency)
        }
    }
    
    func disconnectButtonTapped(deviceNameSerial: DeviceNameSerial) {
        guard let deviceWrapper = discoveredDevices.first(where: { $0.movesenseDevice.serialNumber == deviceNameSerial.serial }) else { return }
        
        Task { @MainActor in
            
            let disconnectedDevice = try await bluetoothClient.disconnectDevice(deviceWrapper)
            connectedDevices.remove(disconnectedDevice)
            
        }
    }
    
    func ecgViewTapped() {
        //        var settingsEcgModel = ecgViewModel
        //        if let savedViewConfig = persistenceClient.ecgConfiguration.load() {
        //            settingsEcgModel.configuration.viewConfiguration.timeInterval = savedViewConfig.viewConfiguration.timeInterval
        //        }
        route = .ecgSettings( withDependencies(from: self) { .init(
            ecgModel: ecgViewModel,
            computeTime: { [weak self] localIndex, localInterval  in
                self?.computeTime(for: localIndex, interval: localInterval) ?? 0.0
            },
            colorSelected: { _ in })
        })
    }
    
    func isConnectable(deviceSerial: String) -> Bool {
        discoveredDevices.contains{ $0.movesenseDevice.serialNumber == deviceSerial } && !connectedDevices.contains{ $0.movesenseDevice.serialNumber == deviceSerial }
    }
    
    func isDisconnectable(deviceSerial: String) -> Bool {
        connectedDevices.contains{ $0.movesenseDevice.serialNumber == deviceSerial }
    }
    
    func computeTime(for index: Int, interval: Int) -> Double {
        let elapsedTime = Double(index) / Double(ecgViewModel.configuration.frequency)
        // Calculate the time within the current 4-second interval
        let timeValue = elapsedTime.truncatingRemainder(dividingBy: Double(interval))
        
        return timeValue
    }
    
    func colorSelected(_ newColor: Color) {
        self.ecgViewModel.configuration.viewConfiguration.chartColor = newColor
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
        NavigationStack {
            VStack {
                ForEach(vm.previousDevices) { deviceSerialName in
                    DeviceCell(
                        deviceSerialName: deviceSerialName,
                        connectButtonTapped: { vm.connectButtonTapped(deviceNameSerial: deviceSerialName)},
                        disconnectButtonTapped: { vm.disconnectButtonTapped(deviceNameSerial: deviceSerialName)},
                        vm: .init(
                            isConnectEnabled: vm.isConnectable(deviceSerial: deviceSerialName.serial),
                            isDisconnectEnabled: vm.isDisconnectable(deviceSerial: deviceSerialName.serial
                                                                    )))
                    .padding(.horizontal, 16)
                }
                VStack {
                    Text("ECG Preview")
                        .font(.headline3)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 16)
                        .padding(.horizontal, 16)
                    
                    EcgView(
                        model: $vm.ecgViewModel,
                        computeTime: vm.computeTime
                    )
                    .background(Color.white)
                    .padding(.all, 16)
                    .onTapGesture(perform: vm.ecgViewTapped)
                    
                }
                .background(Color.white)
                .cornerRadius(20)
                .padding(.horizontal, 16)
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
            .task { await vm.task() }
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
            .navigationDestination(
                unwrapping: self.$vm.route,
                case: /DashboardViewModel.Destination.ecgSettings
            ) { $ecgSettingsVm in
                EcgSettingsView(vm: ecgSettingsVm)
            }
        }
    }
}

class DeviceCellViewModel: ObservableObject {
    @Published var isConnectEnabled: Bool
    @Published var isDisconnectEnabled: Bool
    
    init(isConnectEnabled: Bool, isDisconnectEnabled: Bool) {
        self.isConnectEnabled = isConnectEnabled
        self.isDisconnectEnabled = isDisconnectEnabled
    }
}

struct DeviceCell: View {
    let deviceSerialName: DeviceNameSerial
    let connectButtonTapped: () -> ()
    let disconnectButtonTapped: () -> ()
    @ObservedObject var vm: DeviceCellViewModel
    
    var body: some View {
        VStack {
            Text(deviceSerialName.localName)
                .foregroundColor(.black)
                .font(.headline2)
                .padding(.all, 16)
            HStack {
                Button("Connect", action: connectButtonTapped)
                    .padding(.all, 16)
                    .buttonStyle(MyButtonStyle.init(style: .primary, isEnabled: vm.isConnectEnabled))
                
                Spacer()
                Button("Disconnect", action: disconnectButtonTapped)
                    .padding(.all, 16)
                    .buttonStyle(MyButtonStyle.init(style: .primary, isEnabled: vm.isDisconnectEnabled))
            }
        }
        .background(Color.white)
        .cornerRadius(20)
    }
}
