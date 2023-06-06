//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 01/05/2023.
//

import Foundation
import Combine
import SwiftUI
import IdentifiedCollections
import MovesenseApi
import StylePackage
import Dependencies
import BluetoothClient
import Model
import PersistenceClient
import Clocks

public class AddDeviceViewModel: ObservableObject, Equatable {
    public static func == (lhs: AddDeviceViewModel, rhs: AddDeviceViewModel) -> Bool {
        return lhs.discoveredDevices.count != rhs.discoveredDevices.count
    }
    
    @Published var discoveredDevices: IdentifiedArrayOf<DeviceWrapper> = []
    @Published var selectedDeviceId: UUID?
    @Published var connectedDevice: DeviceWrapper?
    @Published var isConnecting: Bool = false

    @Dependency(\.bluetoothClient) var bluetoothClient
    @Dependency(\.persistenceClient) var persistenceClient
    @Dependency (\.continuousClock) var clock
    private var discoveredDevicesSubscription: Task<Void, Never>?

    var isConnectButtonEnabled: Bool {
        return selectedDeviceId != nil && connectedDevice == nil && !isConnecting
    }
    let connectedAction: (DeviceWrapper) -> Void

    // MARK: - Public Interface
    
    public init(
        connectedAction: @escaping (DeviceWrapper) -> Void
    ) {
        self.connectedAction = connectedAction
    }
    
    func task() async {
        bluetoothClient.scanDevices()
        
        discoveredDevicesSubscription = Task { [weak self] in
            await self?.subscribeToDiscoveredDevicesStream()
        }
        
        try? await clock.sleep(for: .seconds(1))
        guard discoveredDevices.isEmpty else { return }
        let apiDiscoveredDevices = bluetoothClient.getDiscoveredDevices()
        print("👹 Api discovered devices: \(apiDiscoveredDevices)")
        guard !apiDiscoveredDevices.isEmpty else { return }
        await MainActor.run { [weak self] in
            apiDiscoveredDevices.forEach {
                self?.discoveredDevices.append($0)
            }
        }
    }
    
    func onDisappear() {
        bluetoothClient.stopScanningDevices()
        discoveredDevicesSubscription?.cancel()
    }
    // MARK: - Private Interface
    func subscribeToDiscoveredDevicesStream() async {
        for await device in bluetoothClient.discoveredDevicesStream() {
            await MainActor.run { [weak self] in
                 self?.discoveredDevices.append(device)
            }
        }
    }
    
    // MARK: - Actions
    
    func connectButtonTapped() {
        guard let selectedDeviceId = selectedDeviceId,
        let selectedDevice = discoveredDevices[id: selectedDeviceId] else { return }
        
        bluetoothClient.stopScanningDevices()
        Task { @MainActor in
            do {
                self.isConnecting = true
                let connectedDevice = try await bluetoothClient.connectToDevice(selectedDevice)
                self.connectedDevice = connectedDevice
                persistenceClient.deviceNameSerial.save(.init(deviceWrapper: connectedDevice))
                connectedAction(connectedDevice)
                print("🔌 connected to \(connectedDevice.movesenseDevice)")
            } catch {
                print("❌ Couldn't connect to \(selectedDevice.movesenseDevice) error: \(error.localizedDescription)")
            }
        }
    }
    
    
    func didTapCell(device: DeviceWrapper) {
        guard device.id != selectedDeviceId else { return }
        selectedDeviceId = device.id
    }
}

public struct AddDeviceView: View {
    @ObservedObject var viewModel: AddDeviceViewModel
    
    public init(
        viewModel: AddDeviceViewModel
    ) {
        self.viewModel = viewModel
    }
    public var body: some View {
            ZStack {
                VStack {
                    Divider()
                    VStack {
                        ForEach(viewModel.discoveredDevices) { device in
                            DiscoveredDeviceCell(
                                device: device.movesenseDevice,
                                vm: .init(isSelected: device.id == viewModel.selectedDeviceId)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.didTapCell(device: device)
                            }
                        }
                        Spacer()
                        Button("Connect", action: viewModel.connectButtonTapped)
                            .buttonStyle(MyButtonStyle(
                                style: .primary,
                                isLoading: viewModel.isConnecting,
                                isEnabled: viewModel.isConnectButtonEnabled
                            ))
                    }
                    .padding(.horizontal, 16)
                }
//
//                if viewModel.isScanning {
//                    VStack {
//                        Spacer()
//                        VStack {
//                            LoadingView()
//                                .padding(10)
//                        }
//                        .frame(width: 60, height: 60)
//
//                        Spacer()
//                    }
//
//                }

            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
            .background(Color.background)
            .task {
                await viewModel.task()
            }
            .onDisappear(perform: viewModel.onDisappear)
            .navigationBarTitleDisplayMode(.inline)
        }
}


struct ScanDevicesView_Previews: PreviewProvider {
    static var previews: some View {
        Text("Scan devices preview")
    }
}

class DiscoveredCellViewModel: ObservableObject {
    @Published var isSelected: Bool
    
    init(isSelected: Bool) {
        self.isSelected = isSelected
    }
}
struct DiscoveredDeviceCell: View {
    let device: MovesenseDevice
    @ObservedObject var vm: DiscoveredCellViewModel
    
    var body: some View {
        VStack {
            HStack {
                Image.movesenseDevice
                Text(device.localName)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .font(.title1)
                    .foregroundColor(.black)
                if vm.isSelected {
                    Image.checkedIcon
                } else {
                    Circle()
                        .stroke(Color.separator, lineWidth: 1)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.all, 16)
        }
        .background(vm.isSelected ? Color.background2 : Color.clear)
        .cornerRadius(8)
        .overlay(
            vm.isSelected ? nil : RoundedRectangle(cornerRadius: 8).stroke(Color.separator, lineWidth: 1)
        )
    }
}

