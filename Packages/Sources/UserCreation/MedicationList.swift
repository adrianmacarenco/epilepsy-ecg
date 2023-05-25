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
        case diagnosis
    }
    @Published var route: Destination?
    @Published var diagnosis = ""
    
    public init() {}
    
    var isNextButtonEnabled: Bool {
        diagnosis.count > 2
    }
    
    func nextButtonTapped() {
//        route = .height
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
            TextField(
                "Diagnosis",
                text: $vm.diagnosis,
                prompt: Text("Type").foregroundColor(.gray)
            )
            .textFieldStyle(EcgTextFieldStyle())
            Spacer()
            Button("Next", action: vm.nextButtonTapped)
                .buttonStyle(MyButtonStyle.init(style: .primary, isEnabled: vm.isNextButtonEnabled))
                .disabled(!vm.isNextButtonEnabled)
                .padding(.bottom, 58)
        }
        .padding(.horizontal, 16)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
        .background(Color.background)
        .navigationBarTitleDisplayMode(.inline)
//        .navigationDestination(
//            unwrapping: self.$vm.route,
//            case: /WeightSelectionViewModel.Destination.height
//        ) { $personalIdentityVm in
//            PersonalIdentityView(vm: personalIdentityVm)
//        }
    }
}
