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
import SwiftUINavigation

public class MedicationListViewModel: ObservableObject {
    enum Destination {
        case addMedication(AddMedicationViewModel)
    }
    @Published var route: Destination?
    
    public init() {}
    
    func addMedicationTapped() {
        route = .addMedication(.init())
    }
    
    func closeAddMedicationTapped() {
        route = nil
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
            Text("Current medications")
                .font(.largeInput)
            Text("Provide details about your medical history, particularly any heart conditions or seizure events. This helps us develop a comprehensive understanding of your health and tailor your monitoring plan.")
                .padding(.horizontal, 16)
                .font(.body1)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            Spacer()
            Button("Add medication", action: vm.addMedicationTapped)
                .buttonStyle(MyButtonStyle.init(style: .primary))
                .padding(.bottom, 58)
        }
        .padding(.horizontal, 16)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
        .background(Color.background)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(
            unwrapping: self.$vm.route,
            case: /MedicationListViewModel.Destination.addMedication
        ) { $addMedicationVm in
            NavigationStack {
                AddMedicationView(vm: addMedicationVm)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarBackground(.white, for: .navigationBar)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Close") {
                                vm.closeAddMedicationTapped()
                            }
                        }
                    }
            }
        }
    }
}
