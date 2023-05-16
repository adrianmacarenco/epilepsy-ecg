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
        case intervalSelector
        case frequencySelector
    }
    
    var device: DeviceWrapper?
    @Published var ecgModel: EcgViewModel
    @Published var route: Destination?
    
#warning("Discuss this with ying")
    let availableFrequencies = [64, 128, 256]
    let availableIntervals = Array(stride(from: 4, to: 10, by: 1))
    var index = 0
    var cancellable: AnyCancellable?
    var computeTime: (Int) -> Double
    var colorSelected: (Color) -> ()

    @Dependency(\.persistenceClient) var persistenceClient
    @Dependency(\.bluetoothClient) var bluetoothClient
    
    var shownInterval: Int {
        Int(ecgModel.configuration.viewConfiguration.timeInterval)
    }
    
    var selectedFrequency: Int {
        ecgModel.configuration.frequency
    }
    
    public init(
        device: DeviceWrapper? = nil,
        ecgModel: EcgViewModel,
        computeTime: @escaping(Int) -> Double,
        colorSelected: @escaping(Color) -> ()
    ) {
        self.device = device
        self.ecgModel = ecgModel
        self.computeTime = computeTime
        self.colorSelected = colorSelected
    }

    func onAppear() {
        ecgModel.configurationDidChange = {[weak self] newConfig in
            self?.persistenceClient.ecgConfiguration.save(newConfig)
        }
    }
    
    func task() async {
        
        for await ecgData in bluetoothClient.settingsEcgPacketsStream() {
            print("🤠 \(ecgData)")
//            ecgData.samples.forEach { sample in
//                self.ecgModel.data[index] = Double(sample)
//                index += 1
//            }
        }
    }
    
    func frequencyLabelTapped() {
        route = .frequencySelector
    }
    
    func intervalLabelTapped() {
        route = .intervalSelector
    }
    
    func cancelSelection() {
        route = nil
    }
    
    func confirmSelection(_ selectedValue: Int) {
        switch route {
        case .some(.frequencySelector):
            ecgModel.configuration.frequency = selectedValue
        case .some(.intervalSelector):
            ecgModel.configuration.viewConfiguration.timeInterval = Double(selectedValue)
        default: break
        }
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
//                VStack(alignment: .leading) {
//                    Text("Interval: \(vm.shownInterval, specifier: "%d")")
//                        .font(.title1)
//                    Slider(value: $vm.ecgModel.configuration.timeInterval, in: 4...10) {
//                        Text("Interval")
//                    } minimumValueLabel: {
//                        Text("4")
//                    } maximumValueLabel: {
//                        Text("10")
//                    }
//                    .font(.title1)
//
//                }
                HStack {
                    Text("Interval")
                        .font(.title1)
                    Spacer()
                    Text("\(vm.shownInterval) seconds")
                        .font(.title1)
                        .foregroundColor(.gray)
                }
                .contentShape(Rectangle())
                .onTapGesture(perform: vm.intervalLabelTapped)
                ColorPicker(selection: $vm.ecgModel.configuration.viewConfiguration.chartColor) {
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
        .onAppear(perform: vm.onAppear)
        .task { await vm.task() }
        .sheet(unwrapping: $vm.route, case: /EcgSettingsViewModel.Destination.intervalSelector) { _ in
            NavigationStack {
                EcgConfigPickerView(
                    selectedValue: Int(vm.ecgModel.configuration.viewConfiguration.timeInterval),
                    selectableValues: vm.availableIntervals,
                    confirmSelectedValue: { vm.confirmSelection($0) },
                    cancelSelection: vm.cancelSelection
                )
                .navigationTitle("Configure ECG interval")
            }
            .presentationDetents([.fraction(0.35)])
        }
        .sheet(unwrapping: $vm.route, case: /EcgSettingsViewModel.Destination.frequencySelector) { _ in
            NavigationStack {
                EcgConfigPickerView(
                    selectedValue: vm.selectedFrequency,
                    selectableValues: vm.availableFrequencies,
                    confirmSelectedValue: { vm.confirmSelection($0) },
                    cancelSelection: vm.cancelSelection
                )
                .navigationTitle("Configure ECG frequency")
            }
            .presentationDetents([.fraction(0.35)])
        }
    }
}


struct EcgConfigPickerView<SelectionValue: Hashable & CustomStringConvertible>: View {
    
    @State var selectedValue: SelectionValue
    let selectableValues: [SelectionValue]
    let confirmSelectedValue: (SelectionValue) -> ()
    let cancelSelection: () -> ()
    
    
    var body: some View {
        Picker("Time interval", selection: $selectedValue) {
            ForEach(selectableValues, id: \.self) { item in
                Text(item.description)
            }
        }
        .pickerStyle(.wheel)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    cancelSelection()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Select") {
                    confirmSelectedValue(selectedValue)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

public class BlankViewModel: ObservableObject {
    @Published var textValue = "My blank view"
    
    deinit {
        print("❌")
    }
}


public struct BlankView: View {
    @ObservedObject var vm: BlankViewModel
    
    public init(vm: BlankViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        Text(vm.textValue)
    }
}
