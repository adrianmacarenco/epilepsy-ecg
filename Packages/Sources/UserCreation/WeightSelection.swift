import Foundation
import SwiftUI
import Combine
import StylePackage
import SwiftUINavigation

public class WeightSelectionViewModel: ObservableObject {
    enum Destination {
        case height(HeightSelectionViewModel)
    }

    @Published var route: Destination?
    @Published var weight: Double?
    @FocusState var focusedField: WeightSelectionView.Field?
    public init() {}
    
    var isNextButtonEnabled: Bool {
        weight ?? 0.0 > 20.0
    }
    
    func onAppear() {
        focusedField = .weight
    }
    
    func nextButtonTapped() {
        route = .height(.init())
    }
}

public struct WeightSelectionView: View {
    enum Field: Hashable {
        case weight
    }
    @ObservedObject var vm: WeightSelectionViewModel
    @FocusState var focus: Field?

    public init (
        vm: WeightSelectionViewModel
    ) {
        self.vm = vm
    }
    public var body: some View {
        VStack(spacing: 16) {
            Text("Weight-based Assessment")
                .font(.largeInput)
            Text("Enter your current weight. This information is crucial for assessing your overall health and determining appropriate medication dosages if necessary.")
                .padding(.horizontal, 16)
                .font(.body1)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            TextField(
                "Weight",
                value: $vm.weight,
                format: .number,
                prompt: Text("Type your weight in kg").foregroundColor(.gray)
            )
            .textFieldStyle(EcgTextFieldStyle())
            .focused($focus, equals: .weight)
            .keyboardType(.numbersAndPunctuation)
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
            case: /WeightSelectionViewModel.Destination.height
        ) { $heightVm in
            HeightSelectionView(vm: heightVm)
        }
        .onAppear(perform: vm.onAppear)
        .bind(self.$vm.focusedField, to: self.$focus)
    }
}
