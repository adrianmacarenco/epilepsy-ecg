//
//  ContentView.swift
//  Epilepsy ECG
//
//  Created by Adrian Macarenco on 05/03/2023.
//

import SwiftUI
import Combine
import Dependencies
import BluetoothClient

class HomeViewModel: ObservableObject {
    @Dependency(\.bluetoothClient) var bluetoothClient
    
    func task() async {
        for await device in bluetoothClient.discoveredDevicesStream() {
            print("🤡 \(device.isConnected)")
        }
    }
    
    func startScanButtonTapped() {
        bluetoothClient.scanDevices()
    }
}

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        VStack {
            Button("Start scan") {
                viewModel.startScanButtonTapped()
            }
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Searching devices...")
        }
        .padding()
        .task {
            await viewModel.task()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(viewModel: .init())
    }
}
