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

public class AddMedicationViewModel: ObservableObject {
    @Published var medicationName = ""
    @Published var activeIngredients: [ActiveIngredient] = [.init(id: -1, name: "", quantity: 0.0, unit: .mg)]
    
    public init() {
        
    }
    var isAddButtonEnabled: Bool {
        !medicationName.isEmpty && activeIngredients.first?.name != "" && activeIngredients.first?.quantity != 0
    }
    
    var isAddIngredientHidden: Bool {
        activeIngredients.first?.name == "" || activeIngredients.first?.quantity == 0.0 || medicationName.isEmpty
    }
    
    func addIngredientTapped() {
        guard activeIngredients.first?.name != "" && activeIngredients.first?.quantity != 0 else { return }
        activeIngredients.append(.init(id: -1, name: "", quantity: 0.0, unit: .mg))
    }
    
    func addMedicationTapped() {
        
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
            Button("Add medication", action: vm.addMedicationTapped)
                .buttonStyle(MyButtonStyle.init(style: .primary, isEnabled: vm.isAddButtonEnabled))
                .padding(.bottom, 36)
                .disabled(!vm.isAddButtonEnabled)
        }
        .padding(.horizontal, 16)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.background)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Add medication")

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
                    prompt: Text("Type your weight in kg").foregroundColor(.gray)
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
