import Foundation
import SwiftUI
import Combine
import Model
import StylePackage
import SwiftUINavigation
import Dependencies
import DBClient
import PersistenceClient

public class WeightSelectionViewModel: ObservableObject {
    enum Destination {
        case height(HeightSelectionViewModel)
    }

    @Published var route: Destination?
    @Published var weight: Double?
    @Dependency (\.dbClient) var dbClient
    @Dependency (\.persistenceClient) var persistenceClient
    var localUser: User
    
    public init(user: User) {
        self.localUser = user
    }
    
    var isNextButtonEnabled: Bool {
        weight ?? 0.0 > 20.0
    }
    
    func onAppear() {    }
    
    func nextButtonTapped() {
        guard let weight, weight > 20.0 else { return }
        localUser.weight = weight
        route = .height(
            withDependencies(from: self) {
                .init(user: localUser)
            }
        )
    }
}

public struct WeightSelectionView: View {
    @ObservedObject var vm: WeightSelectionViewModel

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
    }
}
