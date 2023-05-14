//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 14/05/2023.
//

import Foundation
import Combine
import SwiftUI
import Model
import StylePackage
import BluetoothClient
import Dependencies
import PersistenceClient
import ECG
import SwiftUINavigation


public class EcgSettingsViewModel: ObservableObject {
    enum Destination: Equatable {
        case frequencySelector
    }
    var device: DeviceWrapper?
    @Published var ecgModel: EcgViewModel
    @Published var selectedFrequency: Int = 128
    @Published var route: Destination?
    
    let possibleFrequncies = [64, 128, 256]
    var computeTime: (Int) -> Double
    var index = 0

    @Dependency(\.persistenceClient) var persistenceClient
    @Dependency(\.bluetoothClient) var bluetoothClient
    
    var shownInterval: Int {
        Int(ecgModel.timeInterval)
    }
    
    public init(
        device: DeviceWrapper? = nil,
        ecgModel: EcgViewModel,
        computeTime: @escaping(Int) -> Double
    ) {
        self.device = device
        self.ecgModel = ecgModel
        self.computeTime = computeTime
    }
    
    func task() async {
        
        for await ecgData in bluetoothClient.ecgPacketsStream() {
            ecgData.samples.forEach { sample in
                self.ecgModel.data[index] = Double(sample)
                index += 1
                
            }
        }
    }
    
    func frequencyLabelTapped() {
        route = .frequencySelector
    }
    
    func cancelEditFrequency() {
        print("cancelEditFrequency")
        route = nil
    }
    
    func frequencySelected() {
        print("frequencySelected \(selectedFrequency)")
        route = nil
    }
}

extension EcgSettingsViewModel: Equatable {
    public static func == (lhs: EcgSettingsViewModel, rhs: EcgSettingsViewModel) -> Bool {
        return lhs.device?.id == lhs.device?.id
    }
    
    
}


public struct EcgSettingsView: View {
    @ObservedObject var vm: EcgSettingsViewModel
    
    public init(
        vm: EcgSettingsViewModel
    ) {
        self.vm = vm
    }
    
    public var body: some View {
        List {
            Section {
                EcgView(
                    model: $vm.ecgModel,
                    computeTime: vm.computeTime
                )
            }
            
            Section {
                VStack(alignment: .leading) {
                    Text("Interval: \(vm.shownInterval, specifier: "%d")")
                        .font(.title1)
                    Slider(value: $vm.ecgModel.timeInterval, in: 4...10) {
                        Text("Interval")
                    } minimumValueLabel: {
                        Text("4")
                    } maximumValueLabel: {
                        Text("10")
                    }
                    .font(.title1)

                }
                ColorPicker(selection: $vm.ecgModel.chartColor) {
                    Text("Color")
                        .font(.title1)
                }
                
                HStack {
                    Text("Frequency")
                        .font(.title1)
                    Spacer()
                    Text("\(vm.selectedFrequency) Hz")
                        .font(.title1)
                        .foregroundColor(.gray)
                }
                .contentShape(Rectangle())
                .onTapGesture(perform: vm.frequencyLabelTapped)
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
        .background(Color.background)
        .navigationTitle("ECG Settings")
        .navigationBarTitleDisplayMode(.large)
        .task {
            
        }
        .sheet(unwrapping: $vm.route, case: /EcgSettingsViewModel.Destination.frequencySelector) {_ in
            NavigationStack {
                Picker("Frequency", selection: $vm.selectedFrequency, content: {
                    ForEach(vm.possibleFrequncies, id: \.self, content: { frequency in
                        Text(frequency.description)
                    })
                })
                .pickerStyle(.wheel)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            vm.cancelEditFrequency()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Select") {
                            vm.frequencySelected()
                        }
                    }
                }
            }
            .presentationDetents([.fraction(0.3)])
        }
    }
}
