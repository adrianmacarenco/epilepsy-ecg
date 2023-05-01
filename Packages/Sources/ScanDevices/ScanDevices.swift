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

public class ScanDevicesViewModel: ObservableObject {
    @Published var discoveredDevices: [MovesenseDevice] = []
    @Published var selectedIndex: Int?
    
    @Dependency(\.bluetoothClient) var bluetoothClient
    
    var isConnectButtonEnabled: Bool {
        return selectedIndex != nil
    }

    public init(){}
    
    @MainActor
    func task() async {
        bluetoothClient.scanDevices()
        for await device in bluetoothClient.discoveredDevicesStream() {
            discoveredDevices.append(device)
        }
    }
    
    func connectButtonTapped() {
        
    }
    
    func didTapCell(index: Int) {
        guard index != selectedIndex else { return }
        selectedIndex = index
    }
}

public struct ScanDevicesView: View {
    @ObservedObject var viewModel: ScanDevicesViewModel
    
    public init(
        viewModel: ScanDevicesViewModel
    ) {
        self.viewModel = viewModel
    }
    public var body: some View {
        VStack {
            ForEach(0 ..< viewModel.discoveredDevices.count, id: \.self) { index in
                DiscoveredDeviceCell(
                    device: viewModel.discoveredDevices[index],
                    vm: .init(isSelected: index == viewModel.selectedIndex)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.didTapCell(index: index)
                }
            }
            Spacer()
            Button("Connect", action: viewModel.connectButtonTapped)
                .buttonStyle(MyButtonStyle(style: .primary, isEnabled: viewModel.isConnectButtonEnabled))

        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 16)
        .background(Color.background)
        .task {
            await viewModel.task()
        }
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
                    Image.checked
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

