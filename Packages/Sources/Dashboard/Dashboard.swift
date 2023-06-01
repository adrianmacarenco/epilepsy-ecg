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
import Onboarding
import ECG_Settings
import DBClient
import DeviceInfo
import Shared
import Combine
import APIClient
import MovesenseApi

public class DashboardViewModel: ObservableObject {
    enum Destination: Equatable {
        case addDevice(AddDeviceViewModel)
        case ecgSettings(EcgSettingsViewModel)
        case onboarding(OnboardingViewModel)
        case deviceInfo(DeviceInfoViewModel)
    }
    
    @Published var route: Destination? {
        didSet {
            print("🏖️ Route has changed: \(route)")
        }
    }
    @Published var previousDevice: DeviceNameSerial?
    @Published var discoveredDevices: IdentifiedArrayOf<DeviceWrapper> = []
    @Published var connectedDevice: DeviceWrapper?
    @Published var ecgViewModel: EcgViewModel = .init(data: [], ecgConfig: .defaultValue)
    @Published var deviceBatteryPercentage: Int?
    
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
    @Dependency(\.apiClient) var apiClient

    // MARK: - Public interface
    
    public init() {
        if let ecgConfig = persistenceClient.ecgConfiguration.load() {
            ecgViewModel.configuration = ecgConfig
        }
        
        fetchCachedDevice()
        bluetoothClient.scanDevices()
        
        // Subscribe to streams
        subscribeToEcgStream()
        subscribeToHrStream()
        
        Task {
            try await clock.sleep(for: .seconds(1))
            guard self.discoveredDevices.isEmpty else { return }
            let apiDiscoveredDevices = bluetoothClient.getDiscoveredDevices()
            print("👹 Api discovered devices: \(apiDiscoveredDevices)")
            guard !apiDiscoveredDevices.isEmpty else { return }
            await MainActor.run { [weak self] in
                apiDiscoveredDevices.forEach {
                    self?.discoveredDevices.append($0)
                }
            }
        }
    }
    
    func onAppear() {
        Task {
            for await device in bluetoothClient.discoveredDevicesStream() {
                await MainActor.run {
                    discoveredDevices.append(device)
                }
            }
        }
        resetEcgData()
        
        Task {
            try await clock.sleep(for: .seconds(2))
            do {
                try await apiClient.uploadDbFile()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func isConnectable(deviceSerial: String) -> Bool {
        discoveredDevices.contains{ $0.movesenseDevice.serialNumber == deviceSerial } && connectedDevice == nil
    }
    
    func isDisconnectable(deviceSerial: String) -> Bool {
        if let connectedDevice, connectedDevice.movesenseDevice.serialNumber == deviceSerial {
            return true
        } else {
            return false
        }
    }
    
    func computeTime(for index: Int, interval: Int) -> Double {
        let elapsedTime = Double(index) / Double(ecgViewModel.configuration.frequency)
        // Calculate the time within the current 4-second interval
        let timeValue = elapsedTime.truncatingRemainder(dividingBy: Double(interval))
        
        return timeValue
    }
    
    // MARK: - Private interface
    
    private func fetchCachedDevice() {
        guard let savedDeviceNameSerial = persistenceClient.deviceNameSerial.load() else { return }
        //Display the previous device here
        previousDevice = savedDeviceNameSerial
    }
    
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
                if count == 3, let connectedDevice {
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
        guard let connectedDevice,
              let ecgConfiguration = persistenceClient.ecgConfiguration.load() else { return }
        ecgViewModel.configuration.frequency = ecgConfiguration.frequency
        bluetoothClient.unsubscribeEcg(connectedDevice)
        bluetoothClient.subscribeToEcg(connectedDevice, ecgViewModel.configuration.frequency)
        resetEcgData()
    }
    
    private func getConnectedDeviceBattery(device: DeviceWrapper) {
        Task { [weak self] in
            let batteryPercentage = try await self?.bluetoothClient.getDeviceBattery(device)
            await MainActor.run { [weak self] in
                withAnimation {
                    self?.deviceBatteryPercentage = batteryPercentage
                    
                }
            }
        }
    }
    
    // MARK: - Actions
    func addDeviceButtonTapped() {
        let addDeviceViewModel = withDependencies(from: self) {
            AddDeviceViewModel(connectedAction: { [weak self] device in
                Task { [weak self] in
                    await MainActor.run { [weak self] in
                        self?.route = nil
                        self?.connectedDevice = device
                        self?.previousDevice = .init(deviceWrapper: device)
                    }
                    
                    self?.bluetoothClient.stopScanningDevices()
                    self?.bluetoothClient.subscribeToHr(device)
                    self?.getConnectedDeviceBattery(device: device)
                }
            })
        }
        route = .addDevice(addDeviceViewModel)
    }
    
    func cancelAddDeviceTapped() {
        route = nil
    }
    
    func closeOnboarding() {
        route = nil
    }
    
    func connectButtonTapped(deviceNameSerial: DeviceNameSerial) {
        guard let deviceWrapper = discoveredDevices.first(where: { $0.movesenseDevice.serialNumber == deviceNameSerial.serial }) else {
            return
        }
        
        Task { @MainActor in
            let connectedDevice = try await self.bluetoothClient.connectToDevice(deviceWrapper)
            self.connectedDevice = connectedDevice
            bluetoothClient.stopScanningDevices()
            bluetoothClient.subscribeToHr(connectedDevice)
            getConnectedDeviceBattery(device: connectedDevice)
            //            saveEcgData()
        }
    }
    
    func disconnectButtonTapped(deviceNameSerial: DeviceNameSerial) {
        guard let deviceWrapper = discoveredDevices.first(where: { $0.movesenseDevice.serialNumber == deviceNameSerial.serial }) else { return }
        
        Task { @MainActor in
            _ = try await bluetoothClient.disconnectDevice(deviceWrapper)
            connectedDevice = nil
        }
    }
    
    func ecgViewTapped() {
        let ecgSettingVm: EcgSettingsViewModel = withDependencies(from: self) { .init(
            device: connectedDevice,
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
    
    func colorSelected(_ newColor: Color) {
        self.ecgViewModel.configuration.viewConfiguration.chartColor = newColor
    }
    
    func deviceCellTapped(_ cachedDevice: DeviceNameSerial) {
        guard let connectedDevice,
              cachedDevice.serial == connectedDevice.movesenseDevice.serialNumber else { return }
        route = .deviceInfo(
            withDependencies(from: self, operation: {
                DeviceInfoViewModel(
                    connectedDevice: connectedDevice,
                    onConfirmDeletion: { [weak self] in
                        guard let connectedDevice = self?.connectedDevice else { return }
                        self?.bluetoothClient.unsubscribeEcg(connectedDevice)
                        self?.bluetoothClient.unsubscribeHr(connectedDevice)
                        Task { [weak self] in
                            _ = try await self?.bluetoothClient.disconnectDevice(connectedDevice)
                            await MainActor.run { [weak self] in
                                self?.route = nil
                                self?.resetEcgData()
                                self?.connectedDevice = nil
                                self?.discoveredDevices = []
                                self?.persistenceClient.deviceNameSerial.save(nil)
                                self?.previousDevice = nil
                            }
                        }
                    }
                )
            })
        )
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
            GeometryReader { proxy in
                
                ScrollView {
                    VStack {
                        if let prevDevice = vm.previousDevice {
                            DeviceCell(
                                deviceSerialName: prevDevice,
                                connectButtonTapped: { vm.connectButtonTapped(deviceNameSerial: prevDevice)},
                                disconnectButtonTapped: { vm.disconnectButtonTapped(deviceNameSerial: prevDevice)},
                                vm: .init(
                                    isConnectEnabled: vm.isConnectable(deviceSerial: prevDevice.serial),
                                    isDisconnectEnabled: vm.isDisconnectable(deviceSerial: prevDevice.serial),
                                    batteryPercentage: vm.connectedDevice != nil ? vm.deviceBatteryPercentage : nil
                                )
                            )
                            .padding(.horizontal, 16)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                vm.deviceCellTapped(prevDevice)
                            }
                            VStack {
                                Text("ECG Preview")
                                    .font(.headline3)
                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, 16)
                                    .padding(.horizontal, 16)
                                HStack {
                                    Text("See more")
                                        .font(.body1)
                                        .foregroundColor(.gray)
                                    Image.openIndicator
                                        .foregroundColor(.gray)
                                    Spacer()
                                    
                                }
                                .padding(.horizontal, 16)
                                EcgView(
                                    model: $vm.ecgViewModel,
                                    computeTime: vm.computeTime
                                )
                                .background(Color.white)
                                .padding([.horizontal, .bottom], 16)
                                .onTapGesture(perform: vm.ecgViewTapped)
                                
                            }
                            .background(Color.white)
                            .cornerRadius(20)
                            .padding(.horizontal, 16)
                            Spacer()
                            
                        } else {
                            GetStartedView()
                            Spacer()
                            Button("Add my device", action: vm.addDeviceButtonTapped)
                                .buttonStyle(MyButtonStyle.init(style: .primary))
                                .padding(.horizontal, 16)
                                .padding(.bottom, 24)
                        }
                        
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
                    .frame(height: proxy.size.height)
                    .navigationTitle("Dashboard")
                    .onAppear(perform: vm.onAppear)
                }
                .background(Color.background)
                
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
                .sheet(
                    unwrapping: self.$vm.route,
                    case: /DashboardViewModel.Destination.onboarding
                ) { $onboardingVm in
                    NavigationStack {
                        OnboardingView(vm: onboardingVm)
                            .toolbarBackground(.visible, for: .navigationBar)
                            .toolbarBackground(.white, for: .navigationBar)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("Close") {
                                        vm.closeOnboarding()
                                    }
                                }
                            }
                    }
                    
                }
                .navigationDestination(
                    unwrapping: self.$vm.route,
                    case: /DashboardViewModel.Destination.deviceInfo
                ) { $deviceInfoVm in
                    DeviceInfoView(vm: deviceInfoVm)
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
}

class DeviceCellViewModel: ObservableObject {
    @Published var isConnectEnabled: Bool
    @Published var isDisconnectEnabled: Bool
    @Published var batteryPercentage: Int?
    init(
        isConnectEnabled: Bool,
        isDisconnectEnabled: Bool,
        batteryPercentage: Int?
    ) {
        self.isConnectEnabled = isConnectEnabled
        self.isDisconnectEnabled = isDisconnectEnabled
        self.batteryPercentage = batteryPercentage
    }
    
    var batteryIcon: Image {
        guard let batteryPercentage else { return Image.batteryLowIcon }
        switch batteryPercentage {
        case 76...100:
            return Image.batteryFullIcon
        case 51...75:
            return Image.batterySecondFullIcon
        case 26...50:
            return Image.batteryHalfIcon
        case 11...25:
            return Image.batteryQuarterIcon
        case 0...10:
            return Image.batteryLowIcon
        default:
            return Image.batteryLowIcon
        }
    }
}

struct DeviceCell: View {
    let deviceSerialName: DeviceNameSerial
    let connectButtonTapped: () -> ()
    let disconnectButtonTapped: () -> ()
    @ObservedObject var vm: DeviceCellViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(deviceSerialName.localName)
                    .font(.headline2)
                    .foregroundColor(.black)
                Spacer()
                if let percentageValue = vm.batteryPercentage {
                    Text("\(percentageValue)%")
                        .font(.sectionTitle)
                        .foregroundColor(.tint1)
                    vm.batteryIcon
                }
            }
            .padding([.horizontal, .top], 16)
            
            HStack {
                Text("See more")
                    .font(.body1)
                    .foregroundColor(.gray)
                Image.openIndicator
                    .foregroundColor(.gray)
                Spacer()
                
            }
            .padding(.horizontal, 16)
            .opacity(vm.isDisconnectEnabled ? 1 : 0)
            
            HStack {
                Button("Connect", action: connectButtonTapped)
                    .padding(.all, 16)
                    .buttonStyle(MyButtonStyle.init(style: .primary, isEnabled: vm.isConnectEnabled))
                
                Spacer()
                Button("Disconnect", action: disconnectButtonTapped)
                    .padding(.all, 16)
                    .buttonStyle(MyButtonStyle.init(style: .primary, isEnabled: vm.isDisconnectEnabled))
            }
            .padding(.top, 10)
        }
        .background(Color.white)
        .cornerRadius(20)
    }
}

struct GetStartedView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image.addFirstDeviceIcon
                .padding(.top, 32)
            
            Text("Monitor your heart activity")
                .font(.largeInput)
                .padding(.horizontal, 16)
            
            Text("Get started by adding your Movesense device")
                .font(.body1)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
        .background(Color.background)
    }
}
