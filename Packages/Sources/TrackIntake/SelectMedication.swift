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
import Shared
import SwiftUINavigation
import UserCreation
import Dependencies
import DBClient
import PersistenceClient
import Localizations

public class SelectMedicationViewModel: ObservableObject {
    enum Destination {
        case addMedication(AddMedicationViewModel)
    }
    @Published var medications: [Medication]
    @Published var selectedMedicationId: Int?
    @Published var route: Destination?
    @Dependency (\.dbClient) var dbClient
    @Dependency (\.persistenceClient) var persistenceClient
    
    var medicationSelected: (Medication) -> Void
    
    // MARK: - Public Interface
    
    public init(
        medications: [Medication],
        medicationSelected: @escaping (Medication) -> Void
    ) {
        self.medications = medications
        self.medicationSelected = medicationSelected
    }
    
    // MARK: - Private Interface
    
    private func medicationAdded() {
        Task { @MainActor in
            self.route = nil
            let updatedMedications = try await dbClient.fetchMedications()
            self.medications = updatedMedications
        }
    }
    
    // MARK: - Actions
    func didTapCell(with index: Int) {
        selectedMedicationId = index
    }
    
    func selectButtonTapped() {
        guard let selectedMedicationId,
              selectedMedicationId < medications.count else { return }
        medicationSelected(medications[selectedMedicationId])
    }
    
    func addMedicationTapped() {
        route = .addMedication(.init(type: .add, medicationAdded: { [weak self] _ in self?.medicationAdded()}))
    }
}

public struct SelectMedicationView: View {
    @ObservedObject var vm: SelectMedicationViewModel
    @EnvironmentObject var localizations: ObservableLocalizations

    init(
        vm: SelectMedicationViewModel
    ) {
        self.vm = vm
    }
    
    public var body: some View {
        ScrollView {
            VStack {
                ForEach(0 ..< vm.medications.count, id: \.self) { index in
                    DiscoveredDeviceCell(vm: .init(
                        medication: vm.medications[index],
                        isSelected: vm.selectedMedicationId == index
                    ))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        vm.didTapCell(with: index)
                    }
                }
                
                DashedFrameView(title: localizations.trackIntakeSection.addMedicationBtnTitle, tapAction: vm.addMedicationTapped)
                    .padding(.top, 8)
            }
            .padding(16)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
            .navigationTitle(localizations.trackIntakeSection.selectMedicationNavTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if vm.selectedMedicationId != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(localizations.defaultSection.select.capitalizedFirstLetter()) {
                            vm.selectButtonTapped()
                        }
                    }
                }

            }
            .navigationDestination(
                unwrapping: self.$vm.route,
                case: /SelectMedicationViewModel.Destination.addMedication
            ) { $addMedicationVm in
                AddMedicationView(vm: addMedicationVm)
                //                .toolbar {
                //                    ToolbarItem(placement: .navigationBarTrailing) {
                //                    Button("Close") {
                //                        vm.closeAddMedicationTapped()
                //                    }
                //                  }
                //                }
            }
        }
        
    }
}

class DiscoveredCellViewModel: ObservableObject {
    @Published var isSelected: Bool
    let medication: Medication
    
    init(
        medication: Medication,
        isSelected: Bool
        
    ) {
        self.medication = medication
        self.isSelected = isSelected
    }
    
    var subtitle: String? {
        if medication.activeIngredients.count == 1, let firstMedication = medication.activeIngredients.first {
            return "\(firstMedication.quantity) \(firstMedication.unit.rawValue)"
        } else {
            return nil
        }
    }
}
struct DiscoveredDeviceCell: View {
    @ObservedObject var vm: DiscoveredCellViewModel
    
    var body: some View {
        HStack {
            Image.pillIcon
                .padding(.leading, 16)
                .padding(.vertical, 16)
            VStack(alignment: .leading) {
                Text(vm.medication.name)
                    .font(.title1)
                    .foregroundColor(.black)
                if let subtitle = vm.subtitle {
                    Text(subtitle)
                        .font(.body1)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
            
            if vm.isSelected {
                Image.checkedIcon
                    .padding(.trailing, 16)
            } else {
                Circle()
                    .stroke(Color.separator, lineWidth: 1)
                    .frame(width: 24, height: 24)
                    .padding(.trailing, 16)

            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 48, alignment: .center)
        .background(vm.isSelected ? Color.background2 : Color.clear)
        .cornerRadius(8)
        .overlay(
            vm.isSelected ? nil : RoundedRectangle(cornerRadius: 8).stroke(Color.separator, lineWidth: 1)
        )
    }
}

