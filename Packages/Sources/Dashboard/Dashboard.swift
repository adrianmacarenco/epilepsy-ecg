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
import DBClient
import Shared
import Combine
import MovesenseApi

public class DashboardViewModel: ObservableObject {
    enum Destination: Equatable {
        case addDevice(AddDeviceViewModel)
        case ecgSettings(EcgSettingsViewModel)
    }
    
    @Published var route: Destination? {
        didSet {
            print("🏖️ Route has changed: \(route)")
        }
    }
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
    var ecgDataEvents: [(MovesenseEcg, Date)] = []
    var localEcgBuffer: [Movesense] = []
    var ecgDataStream: ((MovesenseEcg) -> Void)?
    
    @Dependency (\.persistenceClient) var persistenceClient
    @Dependency (\.bluetoothClient) var bluetoothClient
    @Dependency (\.continuousClock) var clock
    @Dependency (\.dbClient) var dbClient

    // MARK: - Public interface

    public init() {
        if let ecgConfig = persistenceClient.ecgConfiguration.load() {
            ecgViewModel.configuration = ecgConfig
        }
        
        if let savedDeviceNameSerial = persistenceClient.deviceNameSerial.load() {
            //Display the previous device here
            previousDevices.append(savedDeviceNameSerial)
            bluetoothClient.scanDevices()
        }
        subscribeToEcgStream()
        subscribeToHrStream()
    }
    
    func onAppear() {
        resetEcgData()
    }
    
    @MainActor
    func task() async {
        Task {
            for await device in bluetoothClient.discoveredDevicesStream() {
                discoveredDevices.append(device)
            }
        }
        
        Task {
            try await clock.sleep(for: .seconds(1))
            guard self.discoveredDevices.isEmpty else { return }
            let apiDiscoveredDevices = bluetoothClient.getDiscoveredDevices()
            print("👹 Api discovered devices: \(apiDiscoveredDevices)")
            guard !apiDiscoveredDevices.isEmpty else { return }

            apiDiscoveredDevices.forEach {
                self.discoveredDevices.append($0)
            }
        }
    }
    
    // MARK: - Private interface
    private func resetEcgData() {
        index = 0
        ecgViewModel.data = Array(repeating: 0.0, count: previewIntervalSamplesNr)
    }
    
    private func subscribeToEcgStream() {
        guard !hasSubscribedToEcg else { return }
        hasSubscribedToEcg = false
        Task { @MainActor in
            for await ecgData in bluetoothClient.dashboardEcgPacketsStream() {
                ecgDataStream?(ecgData)
                ecgDataEvents.append((ecgData, Date()))
                guard self.route == nil else { continue }
                ecgData.samples.forEach { sample in
                    var finalSample = Double(sample)
                    if sample < ecgViewModel.configuration.viewConfiguration.minValue {
                        finalSample = Double(ecgViewModel.configuration.viewConfiguration.minValue)
                    } else if sample >   ecgViewModel.configuration.viewConfiguration.maxValue {
                        finalSample = Double(ecgViewModel.configuration.viewConfiguration.maxValue)
                    }
                    ecgViewModel.data[index] =  finalSample
                    index += 1
                    if index ==  previewIntervalSamplesNr {
                        index = 0
                        ecgViewModel.data = Array(repeating: 0.0, count: previewIntervalSamplesNr)
                    }
                    
                }
            }
        }
    }
    
    // Subscribes to 5 HR, calculates the average HR and then unsubscribes
    private func subscribeToHrStream() {

        Task {
            var count: Float = 0.0
            var isFirstDiscarded = false
            var totalHr: Float = 0.0
            for await hrRate in bluetoothClient.hrStream() {
                if isFirstDiscarded {
                    totalHr += hrRate.average
                    count += 1
                    Task {@MainActor in
                        withAnimation(Animation.easeInOut) {
                            self.ecgViewModel.scaleFactor = self.ecgViewModel.scaleFactor == 1.0 ? 1.5 : 1.0
                        }
                    }
                } else {
                    isFirstDiscarded = true
                }
                if count == 3, let connectedDevice = connectedDevices.first {
                    bluetoothClient.unsubscribeHr(connectedDevice)
                    bluetoothClient.subscribeToEcg(connectedDevice, ecgViewModel.configuration.frequency)
                    let avrHr = Int(totalHr / count)
                    Task { @MainActor in
                        self.ecgViewModel.avrHr = avrHr
                        withAnimation(Animation.easeInOut) {
                            self.ecgViewModel.scaleFactor = 1.0
                        }
                    }
                    
                }
            }
        }
    }
    
    private func deleteDb() {
        Task {
            do {
                try await dbClient.deleteCurrentDb()
                print("Db deleted 💀")
            } catch {
                print("db couln't be delete \(error)")
            }
        }
    }
    
    // Saves ecg data to the local db every 5 seconds
    // Empty the local array every time after a successful saving
    private func saveEcgData() {
        Task(priority: .background) {
            for await _ in clock.timer(interval: .seconds(5)) {
                let localData = ecgDataEvents.map { (Date(), $0.0.samples.commaSeparatedString()) }
                do {
                    try await dbClient.addEcg(localData)
                    ecgDataEvents = []
                    print("Data saved ✅")
//                    let ecgDtos = try await dbClient.fetchRecentEcgData(3600)
//                    print(ecgDtos)
                } catch {
                    print("🥴 error when saving: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Saves ecg data to the local db every 5 seconds
    // Empty the local array every time after a successful saving
    private func uploadEcgToServer() {
        Task(priority: .background) {
            for await _ in clock.timer(interval: .seconds(300)) {
                print("Upload db file to server")
            }
        }
    }
    
    private func colorChanged() {
        guard let newColor = persistenceClient.ecgConfiguration.load()?.viewConfiguration.chartColor else { return }
        ecgViewModel.configuration.viewConfiguration.chartColor = newColor
    }
    
    private func frequencyChanged() {
        guard let connectedDevice = connectedDevices.first,
        let ecgConfiguration = persistenceClient.ecgConfiguration.load() else { return }
        ecgViewModel.configuration.frequency = ecgConfiguration.frequency
        bluetoothClient.unsubscribeEcg(connectedDevice)
        bluetoothClient.subscribeToEcg(connectedDevice, ecgViewModel.configuration.frequency)
        resetEcgData()
    }

    // MARK: - Actions
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
            bluetoothClient.subscribeToHr(connectedDevice)
//            saveEcgData()
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
        let ecgSettingVm: EcgSettingsViewModel = withDependencies(from: self) { .init(
            device: self.connectedDevices.first,
            ecgModel: ecgViewModel,
            index: self.index ,
            computeTime: { [weak self] localIndex, localInterval  in
                self?.computeTime(for: localIndex, interval: localInterval) ?? 0.0
            },
            colorChanged: { [weak self] in self?.colorChanged()},
            frequencyChanged: { [weak self] in self?.frequencyChanged()}
        )
        }
        self.ecgDataStream = ecgSettingVm.ecgDataStream
        route = .ecgSettings(ecgSettingVm)
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
