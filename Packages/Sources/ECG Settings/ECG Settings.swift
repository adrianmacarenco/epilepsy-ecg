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
    
    public enum EcgChartType: String, CaseIterable, Equatable {
        case live = "Live"
        case history = "History"
    }
    
    var device: DeviceWrapper?
    @Published var ecgModel: EcgViewModel
    @Published var route: Destination?
    @Published var ecgChartType: EcgChartType = .live
    @Published var selectedHistoryOption = 60
    
    
    let availableFrequencies = [128, 256]
    let availableIntervals = Array(stride(from: 4, to: 20, by: 1))
    let availableHistoryOptions = [60, 600, 3600, 86400]
    var index = 0
    var computeTime: (Int, Int) -> Double
    var colorSelected: (Color) -> ()

    @Dependency(\.persistenceClient) var persistenceClient
    @Dependency(\.bluetoothClient) var bluetoothClient
    
    var shownInterval: Int {
        Int(ecgModel.configuration.viewConfiguration.timeInterval)
    }
    
    var selectedFrequency: Int {
        ecgModel.configuration.frequency
    }
    
    var previewIntervalSamplesNr: Int {
        ecgModel.configuration.frequency * Int(ecgModel.configuration.viewConfiguration.timeInterval)
    }
    
    public init(
        device: DeviceWrapper? = nil,
        ecgModel: EcgViewModel,
        computeTime: @escaping(Int, Int) -> Double,
        colorSelected: @escaping(Color) -> ()
    ) {
        self.device = device
        self.ecgModel = ecgModel
        self.computeTime = computeTime
        self.colorSelected = colorSelected
        
        if ecgModel.data.count < self.previewIntervalSamplesNr {
            let neededDataCount = previewIntervalSamplesNr - ecgModel.data.count
            let appendingData = Array(repeating: 0.0, count: neededDataCount)
            self.ecgModel.data.append(contentsOf: appendingData)
        }
        
    }

    func onAppear() {
        ecgModel.configurationDidChange = {[weak self] newConfig in
            self?.persistenceClient.ecgConfiguration.save(newConfig)
        }
    }
    
    func task() async {
        
        
        Task { @MainActor in
            for await ecgData in bluetoothClient.dashboardEcgPacketsStream() {
//                print("🤑  \(ecgData)")

                ecgData.samples.forEach { sample in
                    self.ecgModel.data[index] =  Double(sample)
                    index += 1
                    if index ==  previewIntervalSamplesNr {
                        index = 0
                        ecgModel.data = Array(repeating: 0.0, count: previewIntervalSamplesNr)

                    }

                }
            }
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
                VStack(spacing: 16) {
                    Text("ECG Preview")
                        .font(.headline3)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

                    Picker("", selection: $vm.ecgChartType) {
                        ForEach(EcgSettingsViewModel.EcgChartType.allCases, id: \.self) { type in
                            VStack {
                                Text(type.rawValue)
                                    .font(.title1)
                            }
                            
                        }
                    }
                    .pickerStyle(.segmented)
                    Divider()
                    switch vm.ecgChartType {
                    case .live:

                        EcgView(
                            model: $vm.ecgModel,
                            computeTime: vm.computeTime
                        )
                    case .history:
                        HistorySegmentedController(
                            selectedVale: $vm.selectedHistoryOption,
                            values: vm.availableHistoryOptions
                        )
                        EcgView(
                            model: $vm.ecgModel,
                            computeTime: vm.computeTime
                        )
                    }
                }
            }
            
            Section {
                HStack {
                    Text("Interval")
                        .font(.title1)
                    Spacer()
                    Text("\(vm.shownInterval) seconds")
                        .font(.title1)
                        .foregroundColor(.gray)
                    Image.pickerIndicator
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
                    Image.pickerIndicator
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


struct HistorySegmentedController: View  {
    @Binding var selectedValue: Int
    @State var values: [Int]
    
    init(
        selectedVale: Binding<Int>,
        values: [Int]
    ) {
        self._selectedValue = selectedVale
        self.values = values
    }
    
    var body: some View {
        HStack {
            ForEach(0..<values.count, id: \.self) { index in
                VStack {
                    Text(values[index].formatTime())
                        .font(.caption1)
                        .multilineTextAlignment(.center)
                }
                .frame(minHeight: 40)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                    .background( values[index] == selectedValue ? Color.tint1 : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .foregroundColor(values[index] == selectedValue ? .white : . gray)
                    .onTapGesture {
                        withAnimation {
                            selectedValue = values[index]

                        }
                    }
            }
        }
    }
    
    
}

extension Int {
    func formatTime() -> String {
        let minutes = self / 60
        let hours = minutes / 60
        let days = hours / 24
        
        if days > 0 {
            return "\(days) day\(days > 1 ? "s" : "")"
        } else if hours > 0 {
            return "\(hours) hour\(hours > 1 ? "s" : "")"
        } else {
            return "\(minutes) minute\(minutes > 1 ? "s" : "")"
        }
    }
}
