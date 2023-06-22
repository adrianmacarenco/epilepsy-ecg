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
import WidgetKit
import WidgetClient
import Localizations

public class DashboardViewModel: ObservableObject {
    enum Destination: Equatable {
        case addDevice(AddDeviceViewModel)
        case ecgSettings(EcgSettingsViewModel)
        case onboarding(OnboardingViewModel)
        case deviceInfo(DeviceInfoViewModel)
    }
    
    @Published var route: Destination?
    @Published var previousDevice: DeviceNameSerial?
    @Published var discoveredDevices: IdentifiedArrayOf<DeviceWrapper> = []
    @Published var connectedDevice: DeviceWrapper?
    @Published var ecgViewModel: EcgViewModel = .init(data: [], ecgConfig: .defaultValue)
    @Published var deviceBatteryPercentage: Int?
    @Published var isConnecting = false
    @Published var isDisconnecting = false
    @Published var shouldRenderEcg = true
    
    var index = 0
    let previewInterval = 4
    let serverUploadInterval: Double = 15 // 5 mins
    let localDbUpdateInterval: Double = 5 // 5 seconds
    let batteryCheckInterval: Double = 15 * 60 // 15 mins
    var previewIntervalSamplesNr: Int {
        ecgViewModel.configuration.frequency * Int(previewInterval)
    }
    var hasSubscribedToEcg = false
    var ecgDataEvents: [(MovesenseEcg, Date)] = []
    var localEcgBuffer: [Movesense] = []
    var ecgDataStream: ((MovesenseEcg) -> Void)?
    private var serverUploadTask: Task<Void, Never>?
    private var dbUpdateTask: Task<Void, Never>?
    private var batteryCheckTask: Task<Void, Never>?
    private var disconnectionTask: Task<Void, Never>?

    @Dependency (\.persistenceClient) var persistenceClient
    @Dependency (\.bluetoothClient) var bluetoothClient
    @Dependency (\.continuousClock) var clock
    @Dependency (\.dbClient) var dbClient
    @Dependency(\.apiClient) var apiClient
    @Dependency(\.widgetClient) var widgetClient
    @Dependency(\.localizations) var localizations

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
        Task(priority: .background) {
            try await uploadDbToServerIfNecessary()
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
    }
    
    func isConnectable(deviceSerial: String) -> Bool {
        discoveredDevices.contains{ $0.movesenseDevice.serialNumber == deviceSerial } && connectedDevice == nil && !isConnecting
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
                let newRecording = (ecgData, Date())
//                print(" ❤️ \(newRecording.1.timeIntervalSince1970) \(newRecording.0.samples.commaSeparatedString())")
                ecgDataEvents.append(newRecording)
                guard self.route == nil, shouldRenderEcg else { continue }
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
                    count = 0
                    totalHr = 0
                }
            }
        }
    }
    
    // Check battery level every 15 mins
    private func startBatteryCheckTask() {
        guard let connectedDevice else { return }
        batteryCheckTask = Task(priority: .background, operation: { [weak self, clock, batteryCheckInterval] in
            for await _ in clock.timer(interval: .seconds(batteryCheckInterval)) {
                self?.getConnectedDeviceBattery(device: connectedDevice)
            }
        })
    }
    
    // Saves ecg data to the local db every 5 seconds
    // Empty the local array every time after a successful saving
    private func startLocalUpdateTimerTask() {
        dbUpdateTask = Task(priority: .background, operation: { [weak self, clock, localDbUpdateInterval] in
            for await _ in clock.timer(interval: .seconds(localDbUpdateInterval)) {
                do {
                    try await self?.updateLocalDbData()
                } catch {
                    print("🥴 error when saving: \(error.localizedDescription)")
                }
            }
        })
    }
    
    private func updateLocalDbData() async throws {
        let localData = ecgDataEvents.map { ($0.1, $0.0.samples.commaSeparatedString()) }
        try await self.dbClient.addEcg(localData)
        ecgDataEvents = []
        print("Update local data ✅")
    }
    
    // Saves ecg data to the local db every 5 seconds
    // Empty the local array every time after a successful saving
    private func startServerDbUploadTimerTask() {
        serverUploadTask = Task(priority: .background, operation: { [weak self, clock, serverUploadInterval] in
            for await _ in clock.timer(interval: .seconds(serverUploadInterval)) {
                do {
                    try await self?.uploadDbToServerIfNecessary()
                } catch {
                    
                }
            }
        })
    }
    
    private func startConnectedDeviceTasks() {
        startLocalUpdateTimerTask()
        startServerDbUploadTimerTask()
        startBatteryCheckTask()
        startDisconnectionStreamTask()
    }
    
    private func cancelConnectedDeviceTasks() {
        serverUploadTask?.cancel()
        dbUpdateTask?.cancel()
        batteryCheckTask?.cancel()
        disconnectionTask?.cancel()
    }
    
    private func uploadDbToServerIfNecessary() async throws {
        guard try await shouldUploadDataToServer() else { return }
        try await uploadDbToServer()
    }
    
    private func uploadDbToServer() async throws {
        do {
            try await apiClient.uploadDbFile()
        } catch {
            print("🥴 error while uploading to server: \(error.localizedDescription)")
        }
        do {
            try await dbClient.clearEcgEvents()
        } catch {
            print("🥴 error while clearing localEcgEvents: \(error.localizedDescription)")
        }
        persistenceClient.prevEcgUploadingDate.save(Date())
        print("Update to server 👻")

    }
    
    private func shouldUploadDataToServer() async throws -> Bool {
        guard try await !dbClient.isEcgTableEmpty() else {
            return false
        }
        
        guard let prevUploadDate = persistenceClient.prevEcgUploadingDate.load() else {
            return true
        }
        
        return Date().timeIntervalSince(prevUploadDate) >= serverUploadInterval
    }
    
    private func startDisconnectionStreamTask() {
        disconnectionTask = Task { [weak self, bluetoothClient] in
            for await device in bluetoothClient.disconnectionStream() {
                if device.serialNumber == self?.connectedDevice?.movesenseDevice.serialNumber {
                    self?.updateWidgetConnectionStatus(isConnected: false)
                }
            }
        }
    }
    
    private func updateWidgetConnectionStatus(isConnected: Bool) {
        self.widgetClient.updateConnectionStatus(isConnected)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetClient.kind)
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
                    if let batteryPercentage {
                        self?.widgetClient.updateBatteryPercentage(batteryPercentage)
                        WidgetCenter.shared.reloadTimelines(ofKind: WidgetClient.kind)
                    }
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
            self.isConnecting = true
            let connectedDevice = try await self.bluetoothClient.connectToDevice(deviceWrapper)
            self.isConnecting = false
            withAnimation {
                self.connectedDevice = connectedDevice
            }
            bluetoothClient.stopScanningDevices()
            bluetoothClient.subscribeToHr(connectedDevice)
            getConnectedDeviceBattery(device: connectedDevice)
            self.updateWidgetConnectionStatus(isConnected: true)
            self.startConnectedDeviceTasks()
            UIAccessibility.post(notification: .announcement, argument: localizations.accessibilitySection.deviceConnected)
        }
    }
    
    func disconnectButtonTapped(deviceNameSerial: DeviceNameSerial) {
        guard let deviceWrapper = discoveredDevices.first(where: { $0.movesenseDevice.serialNumber == deviceNameSerial.serial }) else { return }
        
        Task { @MainActor in
            self.isDisconnecting = true
            _ = try await bluetoothClient.disconnectDevice(deviceWrapper)
            self.isDisconnecting = false
            withAnimation {
                connectedDevice = nil
            }
            resetEcgData()
            self.updateWidgetConnectionStatus(isConnected: false)
            UIAccessibility.post(notification: .announcement, argument: localizations.accessibilitySection.deviceDisconnected)
        }
        
        Task {
            guard try await !dbClient.isEcgTableEmpty() else { return }
            try await uploadDbToServer()
        }
        cancelConnectedDeviceTasks()
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
    
    func scenePhaseDidChange(newValue: ScenePhase) {
        switch newValue {
        case .background:
            shouldRenderEcg = false
        case .active:
            shouldRenderEcg = true
        default:
            break
        }
    }
}

public struct DashboardView: View {
    @ObservedObject var vm: DashboardViewModel
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject var localizations: ObservableLocalizations

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
                                    isConnecting: vm.isConnecting,
                                    isDisconnecting: vm.isDisconnecting,
                                    batteryPercentage: vm.connectedDevice != nil ? vm.deviceBatteryPercentage : nil
                                )
                            )
                            .padding(.horizontal, 16)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                vm.deviceCellTapped(prevDevice)
                            }
                            ecgPreview
                            .background(Color.white)
                            .cornerRadius(20)
                            .padding(.horizontal, 16)
                            Spacer()
                            
                        } else {
                            GetStartedView()
                            Spacer()
                            Button(localizations.dashboardSection.addMyDevice, action: vm.addDeviceButtonTapped)
                                .buttonStyle(MyButtonStyle.init(style: .primary))
                                .padding(.horizontal, 16)
                                .padding(.bottom, 24)
                        }
                        
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
                    .frame(height: proxy.size.height)
                    .navigationTitle(localizations.dashboardSection.dashboardTitle)
                    .onAppear(perform: vm.onAppear)
                }
                .background(Color.background)
                .onChange(of: scenePhase, perform: vm.scenePhaseDidChange(newValue:))
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
                                        Text(localizations.defaultSection.cancel.capitalizedFirstLetter())
                                    }
                                }
                            }
                            .toolbar {
                                ToolbarItem(placement: .principal) {
                                    Text(localizations.dashboardSection.addDevice)
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
                                    Button(localizations.defaultSection.close.capitalizedFirstLetter()) {
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
    
    private var ecgPreview: some View {
        VStack {
            Text(localizations.dashboardSection.ecgPreviewTitle)
                .font(.headline3)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .padding(.top, 16)
                .padding(.horizontal, 16)
            VStack {
                if vm.connectedDevice != nil {
                    HStack {
                        Text(localizations.defaultSection.seeMore.capitalizedFirstLetter())
                            .font(.body1)
                            .foregroundColor(.gray)
                        Image.openIndicator
                            .foregroundColor(.gray)
                        Spacer()
                        
                    }
                    EcgView(
                        model: $vm.ecgViewModel,
                        computeTime: vm.computeTime
                    )
                    .padding(.bottom, 16)
                } else {
                    ecgPlaceholder
                }
            }
            .padding(.horizontal, 16)
            .onTapGesture(perform: vm.ecgViewTapped)
        }
    }
    
    private var ecgPlaceholder: some View {
        VStack {
            Image.onboardingConnect
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 100)
                .padding(.bottom, 16)

            Text(localizations.dashboardSection.ecgPlaceholderTitle)
                .font(.largeInput)
                .padding(.bottom, 6)
                .accessibilityHidden(true)

            Text(localizations.dashboardSection.ecgPlaceholderMessage)
                .font(.body1)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .accessibilityHidden(true)

        }
        .padding(.bottom, 16)
        .frame(height: 300)
    }
}

class DeviceCellViewModel: ObservableObject {
    @Published var isConnectEnabled: Bool
    @Published var isDisconnectEnabled: Bool
    @Published var isConnecting: Bool
    @Published var isDisconnecting: Bool
    @Published var batteryPercentage: Int?
    
    init(
        isConnectEnabled: Bool,
        isDisconnectEnabled: Bool,
        isConnecting: Bool,
        isDisconnecting: Bool,
        batteryPercentage: Int?
    ) {
        self.isConnectEnabled = isConnectEnabled
        self.isDisconnectEnabled = isDisconnectEnabled
        self.isConnecting = isConnecting
        self.isDisconnecting = isDisconnecting
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
    @EnvironmentObject var localizations: ObservableLocalizations

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
                Text(localizations.defaultSection.seeMore.capitalizedFirstLetter())
                    .font(.body1)
                    .foregroundColor(.gray)
                Image.openIndicator
                    .foregroundColor(.gray)
                Spacer()
                
            }
            .padding(.horizontal, 16)
            .opacity(vm.isDisconnectEnabled ? 1 : 0)
            
            HStack {
                Button(localizations.defaultSection.connect.capitalizedFirstLetter(), action: connectButtonTapped)
                    .padding(.all, 16)
                    .buttonStyle(MyButtonStyle.init(
                        style: .primary,
                        isLoading: vm.isConnecting,
                        isEnabled: vm.isConnectEnabled
                    ))
                
                Spacer()
                Button(localizations.defaultSection.disconnect.capitalizedFirstLetter(), action: disconnectButtonTapped)
                    .padding(.all, 16)
                    .buttonStyle(MyButtonStyle.init(
                        style: .primary,
                        isLoading: vm.isDisconnecting,
                        isEnabled: vm.isDisconnectEnabled
                    ))
                    .disabled(!vm.isDisconnectEnabled)

            }
            .padding(.top, 10)
        }
        .background(Color.white)
        .cornerRadius(20)
    }
}

struct GetStartedView: View {
    @EnvironmentObject var localizations: ObservableLocalizations

    var body: some View {
        VStack(spacing: 16) {
            Image.addFirstDeviceIcon
                .padding(.top, 32)
            
            Text(localizations.dashboardSection.getStartedTitle)
                .font(.largeInput)
                .padding(.horizontal, 16)
            
            Text(localizations.dashboardSection.getStartedMessage)
                .font(.body1)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
        .background(Color.background)
    }
}
