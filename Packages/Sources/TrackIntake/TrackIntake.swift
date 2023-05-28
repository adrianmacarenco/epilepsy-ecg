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
import Dependencies
import DBClient
import PersistenceClient
import Shared

public class TrackIntakeViewModel: ObservableObject {
    enum Destination {
        case medicationList
        case intakeHistory(IntakeHistoryViewModel)
        case editIntake(TrackIntakeViewModel)
    }
    
    public enum ActionType {
        case add
        case edit(MedicationIntake)
    }
    
    @Published var medications: [Medication] = []
    @Published var selectedMedication: Medication?
    @Published var pillAmount: Double? = 1
    @Published var selectedDate: Date = Date()
    @Published var dailyIntakes: [MedicationIntake] = []
    @Published var route: Destination?
    @Published var type: ActionType
    @Dependency (\.dbClient) var dbClient
    @Dependency (\.persistenceClient) var persistenceClient
    let intakeEditted: (() -> Void)?
    
    var isAddButtonEnabled: Bool {
        switch type {
        case .add:
            return selectedMedication != nil && pillAmount != nil
        case .edit(let intake):
            guard let selectedMedication, let pillAmount else { return false }
            return intake.medication != selectedMedication || intake.pillQuantity != pillAmount || intake.timestamp != selectedDate

        }
    }
    
    var medicationTitle: String {
        if let selectedMedication {
            return selectedMedication.name
        } else {
            return "Select from your medication list"
        }
    }
    
    var navigationTitle: String {
        switch type {
        case .add:
            return "Track intake"
        case .edit:
            return "Edit intake"
        }
    }
    
    var actionButtonTitle: String {
        switch type {
        case .add:
            return "Track intake"
        case .edit:
            return "Save"
        }
    }
    
    var isAddType: Bool {
        switch type {
        case .add:
            return true
        case .edit:
            return false
        }
    }
    
    //MARK: - Public interface
    
    public init(
        type: ActionType,
        intakeEditted: (() -> Void)? = nil
    ) {
        self.type = type
        self.intakeEditted = intakeEditted
        if case ActionType.edit(let intake) = type {
            presetInputsInfo(from: intake)
        }
    }
    
    func onAppear() {
        
    }
    
    func task() async {
        if isAddType {
            Task {
                await refreshDailyIntakes()
            }
        }
        
        do {
            let medications = try await dbClient.fetchMedications()
            await MainActor.run {
                self.medications = medications
            }
        } catch {
            print(" 🫥 Error \(error)")
        }
    }
    
    func getTimeSubtitle(for intakeIndex: Int) -> String? {
        guard intakeIndex < dailyIntakes.count else { return nil }
        return Date.hourMinuteFormatter.string(from: dailyIntakes[intakeIndex].timestamp )
        
    }
    
    // MARK: - Private Interface
    
    func presetInputsInfo(from intake: MedicationIntake) {
        selectedMedication = intake.medication
        pillAmount = intake.pillQuantity
        selectedDate = intake.timestamp
    }
    
    func refreshDailyIntakes() async {
        do {
            let dailyIntakes = try await dbClient.fetchDailyIntakes()
            await MainActor.run {
                self.dailyIntakes = dailyIntakes
            }
        } catch {
            print("Error fetching dailyIntakes")
        }
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
    
    func actionButtonTapped() {
        guard let selectedMedication, let pillAmount else { return }
        Task {
            do {
                switch type {
                case .add:
                    let newIntake = try await dbClient.addIntake(selectedDate, pillAmount, selectedMedication)
                    if let cachedMedications = persistenceClient.medicationIntakes.load() {
                        persistenceClient.medicationIntakes.save(cachedMedications + [newIntake])
                    } else {
                        persistenceClient.medicationIntakes.save([newIntake])
                    }
                    await MainActor.run {
                        self.selectedMedication = nil
                    }
                case .edit(let prevIntake):
                    var updatedIntake = prevIntake
                    updatedIntake.medication = selectedMedication
                    updatedIntake.pillQuantity = pillAmount
                    updatedIntake.timestamp = selectedDate
                    try await dbClient.updateIntake(updatedIntake)
                    await MainActor.run { [updatedIntake] in
                        self.presetInputsInfo(from: updatedIntake)
                        self.intakeEditted?()
                    }
                }
                
                let dailyIntakes = try await dbClient.fetchDailyIntakes()
                await MainActor.run {
                    self.dailyIntakes = dailyIntakes
                }
            } catch {
                print("🫥 Error: \(error)")
            }
        }
        
    }
    
    func dailyIntakeCellTapped(index: Int) {
        guard index < dailyIntakes.count else { return }
        route  = .editIntake(
            withDependencies(from: self, operation: {
                TrackIntakeViewModel(
                    type: .edit(dailyIntakes[index]),
                    intakeEditted: { [weak self] in
                        Task { @MainActor [weak self] in
                            self?.route = nil
                            await self?.refreshDailyIntakes()
                        }
                    }
                )
            })
        )
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
                
                if vm.isAddType {
                    Text("Daily review")
                        .font(.sectionTitle)
                        .foregroundColor(.sectionTitle)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 22)
                    ForEach( 0 ..< vm.dailyIntakes.count, id: \.self) { index in
                        IntakeCellView(intake: vm.dailyIntakes[index], isDailyPreview: true)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            vm.dailyIntakeCellTapped(index: index)
                        }
                    }
                    HStack {
                        Text("Intake history")
                            .foregroundColor(.black)
                            .font(.body1)
                            .padding(.horizontal, 16)
                        Spacer()
                        Image.openIndicator
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 32)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(8)
                    .foregroundColor(.black)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        vm.openHistoryTapped()
                    }
                }
                Spacer()
                Button(vm.actionButtonTitle, action: vm.actionButtonTapped)
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
            .navigationTitle(vm.navigationTitle)
            .task { await vm.task() }
            .sheet(unwrapping: $vm.route, case: /TrackIntakeViewModel.Destination.medicationList) { _ in
                NavigationStack {
                    SelectMedicationView(vm: .init(
                        medications: self.vm.medications,
                        medicationSelected: vm.medicationSelected(_:)))
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
            .navigationDestination(
                unwrapping: self.$vm.route,
                case: /TrackIntakeViewModel.Destination.editIntake
            ) { $editIntakeVm in
                TrackIntakeView(vm: editIntakeVm)
            }
        }
    }
}

public struct IntakeCellView: View {
    var intake: MedicationIntake
    var isDailyPreview: Bool
    
    public var body: some View {
        HStack {
            Image.clockIcon
                .padding(16)
            VStack(alignment: .leading) {
                Text(intake.medication.name)
                    .font(.title1)
                    .foregroundColor(.black)
                Text(subtitle)
                    .font(.body2)
                    .foregroundColor(.gray)
            }
            Spacer()
            
            Image.openIndicator
                .padding(.trailing, 16)
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 32, alignment: .center)
        .background(Color.white)
        .cornerRadius(8)
    }
    
    var subtitle: String {
        isDailyPreview ? Date.hourMinuteFormatter.string(from: intake.timestamp ) : Date.dayMonthHourMinuteFormatter.string(from: intake.timestamp)
    }
}

