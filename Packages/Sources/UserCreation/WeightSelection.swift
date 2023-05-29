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
    
    public enum ActionType {
        case add
        case edit(User)
    }

    @Published var route: Destination?
    @Published var weight: Double?
    @Dependency (\.dbClient) var dbClient
    @Dependency (\.persistenceClient) var persistenceClient
    let type: ActionType
    var localUser: User
    let userUpdated: ((User) -> Void)?
    
    // MARK: - Public Interface
    
    public init(
        user: User,
        type: ActionType = .add,
        userUpdated: ((User) -> Void)? = nil
    ) {
        self.localUser = user
        self.type = type
        self.userUpdated = userUpdated
        if case let ActionType.edit(initialUser) = type {
            weight = initialUser.weight
        }
    }

    var isActionButtonEnabled: Bool {
        guard let weight, weight > 20.0 else { return false }
        switch type {
        case .add:
            return true
        case .edit(let initialUser):
            return initialUser.weight != weight
        }
    }
    
    var actionButtonTitle: String {
        switch type {
        case .add:
            return "Next"
        case .edit:
            return "Save"
        }
    }
    
    // MARK: - Private interface
    private func updateUser(_ updatedUser: User) {
        Task {
            try await dbClient.updateUser(updatedUser)
            persistenceClient.user.save(updatedUser)
            userUpdated?(updatedUser)
        }
    }
    
    // MARK: - Actions
    func actionButtonTapped() {
        guard let weight, weight > 20.0 else { return }

        switch type {
        case .add:
            localUser.weight = weight
            route = .height(
                withDependencies(from: self) {
                    .init(user: localUser)
                }
            )
        case .edit(let initialUser):
            var updatedUser = initialUser
            updatedUser.weight = weight
            updateUser(updatedUser)
        }
    }
}

public struct WeightSelectionView: View {
    @ObservedObject var vm: WeightSelectionViewModel
    @FocusState private var isFocused: Bool

    public init (
        vm: WeightSelectionViewModel
    ) {
        self.vm = vm
    }
    public var body: some View {
        VStack(spacing: 16) {
            if case WeightSelectionViewModel.ActionType.add = vm.type {
                Text("Weight-based Assessment")
                    .font(.largeInput)
            }
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
            .focused($isFocused)
            Spacer()
            Button(vm.actionButtonTitle, action: vm.actionButtonTapped)
                .buttonStyle(MyButtonStyle.init(style: .primary, isEnabled: vm.isActionButtonEnabled))
                .disabled(!vm.isActionButtonEnabled)
                .padding(.bottom, 58)
        }
        .padding(.horizontal, 16)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
        .background(Color.background)
        .contentShape(Rectangle())
        .onTapGesture {
            self.isFocused = false
        }
        .navigationDestination(
            unwrapping: self.$vm.route,
            case: /WeightSelectionViewModel.Destination.height
        ) { $heightVm in
            HeightSelectionView(vm: heightVm)
        }
    }
}
