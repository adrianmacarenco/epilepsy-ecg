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
import MovesenseApi
import Localizations
import Shared

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
    @Published var ecgChartType: EcgChartType = .live {
        didSet {
            if ecgChartType == .history {
                
            }
        }
    }
    @Published var selectedHistoryOption = 60
    
    
    let availableFrequencies = [128, 256]
    let availableIntervals = Array(stride(from: 4, to: 20, by: 1))
    let availableHistoryOptions = [60, 600, 3600, 86400]
    var index: Int
    var computeTime: (Int, Int) -> Double
    var colorChanged: () -> Void
    var frequencyChanged: () -> Void
    public var ecgDataStream: ((MovesenseEcg) -> Void)?
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
    
    // MARK: - Public interface

    public init(
        device: DeviceWrapper? = nil,
        ecgModel: EcgViewModel,
        index: Int,
        computeTime: @escaping(Int, Int) -> Double,
        colorChanged: @escaping() -> Void,
        frequencyChanged: @escaping() -> Void
    ) {
        self.device = device
        self.ecgModel = ecgModel
        self.index = index
        self.computeTime = computeTime
        self.colorChanged = colorChanged
        self.frequencyChanged = frequencyChanged
        
        if ecgModel.data.count < self.previewIntervalSamplesNr {
            let neededDataCount = previewIntervalSamplesNr - ecgModel.data.count
            let appendingData = Array(repeating: 0.0, count: neededDataCount)
            self.ecgModel.data.append(contentsOf: appendingData)
        }
        self.ecgDataStream = { ecgData in
            guard self.route == nil else { return }

            ecgData.samples.forEach { sample in
                var finalSample = Double(sample)
                if sample < self.ecgModel.configuration.viewConfiguration.minValue {
                    finalSample = Double(self.ecgModel.configuration.viewConfiguration.minValue)
                } else if sample >   self.ecgModel.configuration.viewConfiguration.maxValue {
                    finalSample = Double(self.ecgModel.configuration.viewConfiguration.maxValue)
                }
                Task { @MainActor [finalSample] in
                    self.ecgModel.data[self.index] =  finalSample
                    self.index += 1
                    if self.index ==  self.previewIntervalSamplesNr {
                        self.resetEcgData()
                    }
                }

            }
        }
    }

    func onAppear() {
//        ecgModel.configurationDidChange = {[weak self] newConfig in
//            self?.persistenceClient.ecgConfiguration.save(newConfig)
//        }
    }
    
    func task() async {
        
        
//        Task { @MainActor in
//            for await ecgData in bluetoothClient.dashboardEcgPacketsStream() {
//                print("🤑  \(ecgData) correctTimestamp: \(Date())")
//                guard self.route == nil else { continue }
//
//                ecgData.samples.forEach { sample in
//                    var finalSample = Double(sample)
//                    if sample < ecgModel.configuration.viewConfiguration.minValue {
//                        finalSample = Double(ecgModel.configuration.viewConfiguration.minValue)
//                    } else if sample >   ecgModel.configuration.viewConfiguration.maxValue {
//                        finalSample = Double(ecgModel.configuration.viewConfiguration.maxValue)
//                    }
//                    ecgModel.data[index] =  finalSample
//                    index += 1
//                    if index ==  previewIntervalSamplesNr {
//                        resetEcgData()
//                    }
//
//                }
//            }
//        }
    }
    
    // MARK: - Private interface

    private func resetEcgData() {
        index = 0
        ecgModel.data = Array(repeating: 0.0, count: previewIntervalSamplesNr)
    }
    
    // MARK: - Actions

    func frequencyLabelTapped() {
        route = .frequencySelector
    }
    
    func intervalLabelTapped() {
        route = .intervalSelector
    }
    
    func cancelSelection() {
        resetEcgData()
        route = nil
        
    }
    
    func confirmSelection(_ selectedValue: Int) {
        switch route {
        case .some(.frequencySelector):
            guard selectedValue != ecgModel.configuration.frequency else { break }
            ecgModel.configuration.frequency = selectedValue
            resetEcgData()
            persistenceClient.ecgConfiguration.save(ecgModel.configuration)
            frequencyChanged()
            
        case .some(.intervalSelector):
            guard selectedValue != shownInterval else { break }
            ecgModel.configuration.viewConfiguration.timeInterval = Double(selectedValue)
            resetEcgData()
            
        default: break
        }
        route = nil
    }
    
    
    func colorChanged(_ newColor: Color) {
        ecgModel.configuration.viewConfiguration.chartColor = newColor
        persistenceClient.ecgConfiguration.save(ecgModel.configuration)
        colorChanged()
    }
    
    func unsubscribeEcg() {
        guard let device else { return }
        bluetoothClient.unsubscribeEcg(device)
    }
}

extension EcgSettingsViewModel: Equatable {
    public static func == (lhs: EcgSettingsViewModel, rhs: EcgSettingsViewModel) -> Bool {
        return lhs.device?.id == lhs.device?.id
    }
}


public struct EcgSettingsView: View {
    @ObservedObject var vm: EcgSettingsViewModel
    @EnvironmentObject var localizations: ObservableLocalizations

    public init(
        vm: EcgSettingsViewModel
    ) {
        self.vm = vm
    }
    
    public var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    Text(localizations.ecgSettings.ecgPreviewLabel)
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
                    Text(localizations.defaultSection.interval.capitalizedFirstLetter())
                        .font(.title1)
                    Spacer()
                    Text("\(vm.shownInterval) \(localizations.defaultSection.second.capitalizedFirstLetter())")
                        .font(.title1)
                        .foregroundColor(.gray)
                    Image.pickerIndicator
                        .foregroundColor(.gray)
                }
                .contentShape(Rectangle())
                .onTapGesture(perform: vm.intervalLabelTapped)
                
                ColorPicker(selection: Binding(
                    get: { vm.ecgModel.configuration.viewConfiguration.chartColor },
                    set: vm.colorChanged(_:)) ) {
                        Text(localizations.defaultSection.color.capitalizedFirstLetter())
                        .font(.title1)
                }
                
                HStack {
                    Text(localizations.defaultSection.frequency.capitalizedFirstLetter())
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
        .navigationTitle(localizations.ecgSettings.ecgPreviewScreenTitle)
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
                .navigationTitle(localizations.ecgSettings.configureEcgIntervalTitle)
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
                .navigationTitle(localizations.ecgSettings.configureEcgFreqTitle)
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
    @EnvironmentObject var localizations: ObservableLocalizations

    
    var body: some View {
        Picker("Time interval", selection: $selectedValue) {
            ForEach(selectableValues, id: \.self) { item in
                Text(item.description)
            }
        }
        .pickerStyle(.wheel)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(localizations.defaultSection.cancel.capitalizedFirstLetter()) {
                    cancelSelection()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(localizations.defaultSection.select) {
                    confirmSelectedValue(selectedValue)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
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
