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

public class HeightSelectionViewModel: ObservableObject {
    enum Destination {
        case diagnosis(DiagnosisViewModel)
    }
    @Published var route: Destination?
    @Published var height = 0.0
    
    public init() {}
    
    var isNextButtonEnabled: Bool {
        height > 20.0
    }
    
    func nextButtonTapped() {
        route = .diagnosis(.init())
    }
}

public struct HeightSelectionView: View {
    @ObservedObject var vm: HeightSelectionViewModel
    
    public init (
        vm: HeightSelectionViewModel
    ) {
        self.vm = vm
    }
    public var body: some View {
        VStack(spacing: 16) {
            Text("BMI Calculation")
                .font(.largeInput)
            Text("Please input your height. This, combined with your weight, allows us to calculate your Body Mass Index (BMI) and provide personalized health guidance.")
                .padding(.horizontal, 16)
                .font(.body1)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            TextField(
                "Height",
                value: $vm.height,
                format: .number,
                prompt: Text("Type your height in cm").foregroundColor(.gray)
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
        .navigationDestination(
            unwrapping: self.$vm.route,
            case: /HeightSelectionViewModel.Destination.diagnosis
        ) { $diagnosisIdentityVm in
            DiagnosisView(vm: diagnosisIdentityVm)
        }
    }
}
