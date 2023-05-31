//
//  File.swift
//
//
//  Created by Adrian Macarenco on 22/05/2023.
//

import Foundation
import SwiftUI
import Combine
import StylePackage
import Model
import SwiftUINavigation
import Dependencies
import DBClient
import PersistenceClient
import Shared

public class MedicationListViewModel: ObservableObject {
    enum Destination {
        case addMedication(AddMedicationViewModel)
    }
    
    public enum ActionType {
        case add
        case edit([Medication])
    }
    @Published var route: Destination?
    @Published var medications: [Medication] = []
    
    @Dependency (\.dbClient) var dbClient
    @Dependency (\.persistenceClient) var persistenceClient
    let type: ActionType
    var localUser: User
    var userCreationFlowEnded: () -> Void

    // MARK: - Public Interface
    
    public init(
        user: User,
        type: ActionType = .add,
        userCreationFlowEnded: @escaping() -> Void
    ) {
        self.localUser = user
        self.type = type
        self.userCreationFlowEnded = userCreationFlowEnded
        if case let ActionType.edit(medications) = type {
            self.medications = medications
        }
    }
    var isActionButtonEnabled: Bool {
        return true
    }
    
    var actionButtonTitle: String {
        switch type {
        case .add:
            return "Finish"
        case .edit:
            return "Save"
        }
    }
    
    func getMedicationSubtitle(index: Int) -> String? {
        guard index < medications.count else { return nil}
        let medication = medications[index]
        if medication.activeIngredients.count == 1, let firstMedication = medication.activeIngredients.first {
            return "\(firstMedication.quantity) \(firstMedication.unit.rawValue)"
        } else {
            return nil
        }
    }
    
    // MARK: - Actions
    func actionButtonTapped() {
        switch type {
        case .add:
            // Dismiss flow
            userCreationFlowEnded()
        case .edit:
            break
        }
    }
    
    func addMedicationTapped() {
        route = .addMedication(
            withDependencies(from: self) {
                .init(type: .add, medicationAdded: { [weak self] in self?.medicationAdded($0) })
            }
        )
    }
    
    func editMedicationTapped(index: Int) {
        guard index < medications.count else { return }
        
        route = .addMedication(
            withDependencies(from: self) {
                .init(
                    type: .edit(medications[index]),
                    medicationAdded: { [weak self] in self?.medicationAdded($0) },
                    medicationDeleted: { [weak self] in self?.medicationDeleted($0)})
            }
        )
    }
    
    func medicationAdded(_ medication: Medication) {
        Task { @MainActor in
            route = nil
            if let updatedMedicationIndex = medications.firstIndex(where: { $0.id == medication.id }) {
                medications[updatedMedicationIndex] = medication
            } else {
                medications.append(medication)
            }
        }
    }
    
    func medicationDeleted(_ medication: Medication) {
        Task { @MainActor in
            route = nil
            medications.removeAll(where: { $0.id == medication.id })
        }
    }
    
    func closeAddMedicationTapped() {
        route = nil
    }
    
    func medicationCellTapped(index: Int) {
        guard index < medications.count else { return }
        
    }
}

public struct MedicationListView: View {
    @ObservedObject var vm: MedicationListViewModel
    
    public init (
        vm: MedicationListViewModel
    ) {
        self.vm = vm
    }
    public var body: some View {
        VStack(spacing: 16) {
            if case MedicationListViewModel.ActionType.add = vm.type {
                Text("Current medications")
                    .font(.largeInput)
            }

            Text("Set up your Medication List! This list will contain all your prescribed medications, which you can select from when tracking your daily pill intake. By maintaining an accurate Medication List, you can easily record and monitor your pill intake, ensuring you stay on track with your prescribed regimen. This information is invaluable to us as it enables us to provide you with personalized support and optimize your overall health management.")
                .padding(.horizontal, 16)
                .font(.body1)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            
            ForEach(0 ..< vm.medications.count, id: \.self) { index in
                HStack {
                    Image.pillIcon
                        .padding(16)
                    VStack(alignment: .leading) {
                        Text(vm.medications[index].name)
                            .font(.title1)
                            .foregroundColor(.black)
                        if let subtitle = vm.getMedicationSubtitle(index: index) {
                            Text(subtitle)
                                .font(.body2)
                                .foregroundColor(.gray)
                        }
                    }
                    Spacer()
                    
                    Image.openIndicator
                        .padding(.trailing, 16)
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 32, alignment: .center)
                .background(Color.white)
                .cornerRadius(8)
                .contentShape(Rectangle())
                .onTapGesture {
                    vm.editMedicationTapped(index: index)
                }
            }
            DashedFrameView(title: "Add medication", tapAction: vm.addMedicationTapped)
                .padding(.top, 8)
            Spacer()
            if case MedicationListViewModel.ActionType.add = vm.type {
                Button(vm.actionButtonTitle, action: vm.actionButtonTapped)
                    .buttonStyle(MyButtonStyle.init(style: .primary, isEnabled: vm.isActionButtonEnabled))
                    .disabled(!vm.isActionButtonEnabled)
                    .padding(.bottom, 58)
            }

        }
        .padding(.horizontal, 16)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
        .background(Color.background)
        .sheet(
            unwrapping: self.$vm.route,
            case: /MedicationListViewModel.Destination.addMedication
        ) { $addMedicationVm in
            NavigationStack {
                AddMedicationView(vm: addMedicationVm)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarBackground(.white, for: .navigationBar)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") {
                                vm.closeAddMedicationTapped()
                            }
                        }
                    }
            }
        }
    }
}
