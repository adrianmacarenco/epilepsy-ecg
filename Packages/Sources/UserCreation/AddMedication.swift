//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 25/05/2023.
//

import Foundation
import SwiftUI
import Combine
import StylePackage
import Model
import Shared
import DBClient
import Dependencies
import PersistenceClient


public class AddMedicationViewModel: ObservableObject {
    public enum ActionType {
        case add
        case edit(Medication)
    }
    @Published var medicationName = ""
    @Published var activeIngredients: [ActiveIngredient] = [.init(id: -1, name: "", quantity: 0.0, unit: .mg)]
    @Published var actionType: ActionType
    
    @Dependency (\.dbClient) var dbClient
    @Dependency (\.persistenceClient) var persistenceClient
    private let medicationAdded: (Medication) -> Void
    private let medicationDeleted: ((Medication) -> Void)?

    // MARK: - Public Interface
    public init(
        type: ActionType,
        medicationAdded: @escaping (Medication) -> Void,
        medicationDeleted: ((Medication) -> Void)? = nil
    ) {
        self.medicationAdded = medicationAdded
        self.actionType = type
        self.medicationDeleted = medicationDeleted
        if case ActionType.edit(let initialMed) = type {
            medicationName = initialMed.name
            activeIngredients = initialMed.activeIngredients
        }
    }
    
    var isAddButtonEnabled: Bool {
        switch actionType {
        case .add:
            return !medicationName.isEmpty && activeIngredients.first?.name != "" && activeIngredients.first?.quantity != 0
        case .edit(let medication):
            return isEditButtonEnabled(initialMedication: medication)
        }
    }
    
    var isAddIngredientHidden: Bool {
        activeIngredients.first?.name == "" || activeIngredients.first?.quantity == 0.0 || medicationName.isEmpty
    }
    
    var actionButtonTitle: String {
        switch actionType {
        case .add:
            return "Add"
        case .edit:
            return "Update"
        }
    }
    
    var validIngredients: [ActiveIngredient] {
        activeIngredients.filter { $0.name.count > 2 && $0.quantity > 0}
    }
    
    // MARK: - Private Interface
    
    func isEditButtonEnabled(initialMedication: Medication) -> Bool {
        return initialMedication.name != medicationName || hasIngredientsChanged(prevIngredients: initialMedication.activeIngredients)
    }
    
    func hasIngredientsChanged(prevIngredients: [ActiveIngredient]) -> Bool {
        guard prevIngredients.count == validIngredients.count else { return true }
        
        for (prevIngredient, newIngredient) in zip(prevIngredients, validIngredients) {
            if prevIngredient.name != newIngredient.name ||
               prevIngredient.quantity != newIngredient.quantity ||
               prevIngredient.unit != newIngredient.unit {
                return true
            }
        }
        
        return false
    }
    
    func addMedication() {
        guard medicationName.count > 2, !validIngredients.isEmpty else { return }
        
        Task {
            do {
                let medication = try await dbClient.createMedication(medicationName, validIngredients)
                if let cachedMedications = persistenceClient.medications.load() {
                    persistenceClient.medications.save(cachedMedications + [medication])
                } else {
                    persistenceClient.medications.save([medication])
                }
                medicationAdded(medication)
            } catch {
                print("🫥 ERROR \(error) ")
            }
        }
    }
    
    func editMedication(initialMedication: Medication) {
        guard medicationName.count > 2, !validIngredients.isEmpty else { return }
        let newMedication = Medication(id: initialMedication.id, name: medicationName, activeIngredients: validIngredients)
        Task {
            do {
                try await dbClient.updateMedication(newMedication)
                if let cachedMedications = persistenceClient.medications.load(),
                   let existingIndex = cachedMedications.firstIndex(where: { $0.id == initialMedication.id }) {
                    var updatedMedications = cachedMedications
                    updatedMedications[existingIndex] = newMedication
                    persistenceClient.medications.save(updatedMedications)
                }
                medicationAdded(newMedication)
            } catch {
                print("🫥 ERROR \(error) ")
            }
        }
    }
    

    // MARK: - Actions
    func addIngredientTapped() {
        guard activeIngredients.first?.name != "" && activeIngredients.first?.quantity != 0 else { return }
        activeIngredients.append(.init(id: -1, name: "", quantity: 0.0, unit: .mg))
    }
    
    func actionButtonTapped() {
        switch actionType {
        case .add:
            addMedication()
        case .edit(let initialMedication):
            editMedication(initialMedication: initialMedication)
        }
    }
    
    func deleteMedicationTapped() {
        if case ActionType.edit(let medication) =  self.actionType {
            Task {
                do {
                    try await dbClient.deleteMedication(medication.id)
                    var cachedMedications = persistenceClient.medications.load()
                    cachedMedications?.removeAll(where: { $0.id == medication.id})
                    persistenceClient.medications.save(cachedMedications)
                    medicationDeleted?(medication)
                }
            }
        }
    }
}

public struct AddMedicationView: View {
    @ObservedObject var vm: AddMedicationViewModel
    
    public init(
        vm: AddMedicationViewModel
    ) {
        self.vm = vm
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            Text("Current medications")
                .font(.sectionTitle)
                .foregroundColor(.sectionTitle)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .padding(.top, 22)
            TextField(
                "Diagnosis",
                text: $vm.medicationName,
                prompt: Text("Type").foregroundColor(.gray)
            )
            .textFieldStyle(EcgTextFieldStyle({
                Image.pillIcon
            }))
            Text("Active ingredients")
                .font(.sectionTitle)
                .foregroundColor(.sectionTitle)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .padding(.top, 24)
            VStack {
                ForEach(0 ..< vm.activeIngredients.count, id: \.self) { index in
                    ActiveIngredientCell(
                        name: $vm.activeIngredients[index].name,
                        quantity: $vm.activeIngredients[index].quantity,
                        unit: $vm.activeIngredients[index].unit
                    )
                }
            }
            if !vm.isAddIngredientHidden {
                DashedFrameView(title: "Add active ingredient", tapAction: vm.addIngredientTapped)
                    .padding(.top, 24)
            }
            Spacer()
            if case AddMedicationViewModel.ActionType.edit = vm.actionType{
                Button("Delete medication", action: vm.deleteMedicationTapped)
                    .buttonStyle(MyButtonStyle.init(style: .delete))
                    .padding(.bottom, 58)
            }
            
        }
        .padding(.horizontal, 16)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.background)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Add medication")
        .toolbar {
            if vm.isAddButtonEnabled {
                ToolbarItem(placement: .confirmationAction) {
                    Button(vm.actionButtonTitle) {
                        vm.actionButtonTapped()
                    }
                }
            }
            
        }

    }
}

struct ActiveIngredientCell: View {
    @Binding var name: String
    @Binding var quantity: Double
    @Binding var unit: ActiveIngredient.Unit
    let units = ActiveIngredient.Unit.allCases
    
    var body: some View {
        VStack(spacing: 8) {
            TextField(
                "Active ingredient name",
                text: $name,
                prompt: Text("Type").foregroundColor(.gray)
            )
            .textFieldStyle(EcgTextFieldStyle())
            HStack {
                TextField(
                    "Weight",
                    value: $quantity,
                    format: .number,
                    prompt: Text("Count").foregroundColor(.gray)
                )
                .textFieldStyle(EcgTextFieldStyle())

                Picker("Select an unit", selection: $unit) {
                    ForEach(units, id: \.self) { unit in
                        Text(unit.rawValue)
                    }
                }
                .padding(.bottom, 10)
                .background(Color.white)
                .cornerRadius(12)
                .pickerStyle(.menu)
                .tint(.black)
                
            }
        }
    }
}
