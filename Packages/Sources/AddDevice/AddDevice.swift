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

public class AddDeviceViewModel: ObservableObject, Equatable {
    public static func == (lhs: AddDeviceViewModel, rhs: AddDeviceViewModel) -> Bool {
        return lhs.discoveredDevices.count != rhs.discoveredDevices.count
    }
    
    @Published var discoveredDevices: IdentifiedArrayOf<DeviceWrapper> = []
    @Published var selectedDeviceId: UUID?
    @Published var connectedDevice: DeviceWrapper?

    @Dependency(\.bluetoothClient) var bluetoothClient
    @Dependency(\.persistenceClient) var persistenceClient
    
    var isConnectButtonEnabled: Bool {
        return selectedDeviceId != nil && connectedDevice == nil
    }
    
    var isDisconnectButtonEnabled: Bool {
        return connectedDevice != nil
    }

    public init(){}
    
    @MainActor
    func task() async {
        bluetoothClient.scanDevices()
        for await device in bluetoothClient.discoveredDevicesStream() {
            print(device.movesenseDevice.isConnected)
            discoveredDevices.append(device)
        }
    }
    
    func connectButtonTapped() {
        guard let selectedDeviceId = selectedDeviceId,
        let selectedDevice = discoveredDevices[id: selectedDeviceId] else { return }
        
        bluetoothClient.stopScanningDevices()
        Task { @MainActor in
            do {
                let connectedDevice = try await bluetoothClient.connectToDevice(selectedDevice)
                self.connectedDevice = connectedDevice
                persistenceClient.deviceNameSerial.save(.init(deviceWrapper: connectedDevice))
                print("🔌 connected to \(connectedDevice.movesenseDevice)")
            } catch {
                print("❌ Couldn't connect to \(selectedDevice.movesenseDevice) error: \(error.localizedDescription)")
            }
        }
    }
    
    func disconnectButtonTapped() {
        guard let connectedDevice = connectedDevice else { return }
        Task { @MainActor in
            do {
                let disconnectedDevice = try await bluetoothClient.disconnectDevice(connectedDevice)
                print("🔌 disconnected \(disconnectedDevice.movesenseDevice.localName)")
                self.connectedDevice = nil
                
            } catch {
                print("❌ Couldn't disconnect \(connectedDevice) error: \(error.localizedDescription)")
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
                Button("Disconnnect", action: viewModel.disconnectButtonTapped)
                    .buttonStyle(MyButtonStyle(
                        style: .primary,
                        isEnabled: viewModel.isDisconnectButtonEnabled
                    ))
                Button("Connect", action: viewModel.connectButtonTapped)
                    .buttonStyle(MyButtonStyle(
                        style: .primary,
                        isEnabled: viewModel.isConnectButtonEnabled
                    ))
            }
            .padding(.horizontal, 16)
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
        .background(Color.background)
        .task {
            await viewModel.task()
        }
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

