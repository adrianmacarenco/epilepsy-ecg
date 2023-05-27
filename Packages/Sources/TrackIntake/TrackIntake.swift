//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 26/05/2023.
//

import Foundation
import Combine
import SwiftUI
import Model
import StylePackage
import SwiftUINavigation

public class TrackIntakeViewModel: ObservableObject {
    enum Destination {
        case medicationList
        case intakeHistory(IntakeHistoryViewModel)
    }
    @Published var medications: [Medication] = []
    @Published var selectedMedication: Medication?
    @Published var pillAmount: Double? = 1
    @Published var selectedDate = Date()
    @Published var route: Destination?

    
    var isAddButtonEnabled: Bool {
        return true
    }
    
    var medicationTitle: String {
        if let selectedMedication {
            return selectedMedication.name
        } else {
            return "Select from your medication list"
        }
    }
    
    public init() {
        
    }
    
    func addIntakeTapped() {
        
    }
    
    // MARK: - Actions
    
    func medicationSelectorTapped() {
        route = .medicationList
    }
    
    func openHistoryTapped() {
        route = .intakeHistory(.init())
    }
    
    func medicationSelected(_ medication: Medication) {
        route = nil
        self.selectedMedication = medication
    }
    
    func cancelSelectionTapped() {
        route = nil
    }
}

public struct TrackIntakeView: View {
    @ObservedObject var vm: TrackIntakeViewModel
    @FocusState private var isFocused: Bool

    public init(
        vm: TrackIntakeViewModel
    ) {
        self.vm = vm
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                Text("Medication")
                    .font(.sectionTitle)
                    .foregroundColor(.sectionTitle)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                HStack {
                    Image.pillIcon
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                    Text(vm.medicationTitle)
                        .foregroundColor(vm.selectedMedication != nil ? .black : .gray)
                        .font(.body1)
                    Spacer()
                    Image.pickerIndicator
                        .padding(.horizontal, 16)
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.white)
                .cornerRadius(12)
                .foregroundColor(.black)
                .contentShape(Rectangle())
                .onTapGesture {
                    vm.medicationSelectorTapped()
                }
                Text("Amount & date")
                    .font(.sectionTitle)
                    .foregroundColor(.sectionTitle)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 22)
                HStack {
                    TextField(
                        "Amount",
                        value: $vm.pillAmount,
                        format: .number
                    )
                    .multilineTextAlignment(.center)
                    .textFieldStyle(EcgTextFieldStyle(
                        description: "pills",
                        padding: 7,
                        { Image.pillsIcon }
                    ))
                    .focused($isFocused)
                    
                    DatePicker("", selection: $vm.selectedDate)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
                
                Text("Intake history")
                    .font(.sectionTitle)
                    .foregroundColor(.sectionTitle)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 22)
                HStack {

                    Text("Open")
                        .foregroundColor(.black)
                        .font(.body1)
                        .padding(.horizontal, 10)
                    Spacer()
                    Image.openIndicator
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.white)
                .cornerRadius(12)
                .foregroundColor(.black)
                .contentShape(Rectangle())
                .onTapGesture {
                    vm.openHistoryTapped()
                }
                Spacer()
                Button("Track intake", action: vm.addIntakeTapped)
                    .buttonStyle(MyButtonStyle.init(style: .primary, isEnabled: vm.isAddButtonEnabled))
                    .padding(.bottom, 36)
                    .disabled(!vm.isAddButtonEnabled)
            }
            .padding(.horizontal, 16)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.background)
            .onTapGesture {
                self.isFocused = false
            }
            .navigationTitle("Track intake")
            .sheet(unwrapping: $vm.route, case: /TrackIntakeViewModel.Destination.medicationList) { _ in
                NavigationStack {
                    SelectMedicationView(vm: .init(medicationSelected: vm.medicationSelected(_:)))
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Cancel") {
                                    vm.cancelSelectionTapped()
                                }
                            }
                        }
                    
                }
                .presentationDetents([.medium])
            }
            .navigationDestination(
                unwrapping: self.$vm.route,
                case: /TrackIntakeViewModel.Destination.intakeHistory
            ) { $intakeHistoryVm in
                IntakeHistoryView(vm: intakeHistoryVm)
            }
        }
    }
}

