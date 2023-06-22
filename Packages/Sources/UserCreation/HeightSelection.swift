//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 22/05/2023.
//

import Foundation
import SwiftUI
import Combine
import Model
import StylePackage
import SwiftUINavigation
import Dependencies
import DBClient
import PersistenceClient
import Localizations

public class HeightSelectionViewModel: ObservableObject {
    enum Destination {
        case diagnosis(DiagnosisViewModel)
    }
    
    public enum ActionType {
        case add
        case edit(User)
    }
    @Published var route: Destination?
    @Published var height: Double?
    @Dependency (\.dbClient) var dbClient
    @Dependency (\.persistenceClient) var persistenceClient
    @Dependency (\.localizations) var localizations

    let type: ActionType
    var localUser: User
    let userUpdated: ((User) -> Void)?
    var userCreationFlowEnded: () -> Void = unimplemented("DeviceInfoViewModel.onConfirmDeletion")

    // MARK: - Public Interface
    
    public init(
        user: User,
        type: ActionType = .add,
        userUpdated: ((User) -> Void)? = nil,
        userCreationFlowEnded: @escaping() -> Void
    ) {
        self.localUser = user
        self.type = type
        self.userUpdated = userUpdated
        self.userCreationFlowEnded = userCreationFlowEnded
        if case let ActionType.edit(initialUser) = type {
            height = initialUser.height
        }
    }
    
    var isActionButtonEnabled: Bool {
        guard let height, height > 20.0 else { return false }
        switch type {
        case .add:
            return true
        case .edit(let initialUser):
            return initialUser.height != height
        }
    }
    
    var actionButtonTitle: String {
        switch type {
        case .add:
            return localizations.defaultSection.next.capitalizedFirstLetter()
        case .edit:
            return localizations.defaultSection.save.capitalizedFirstLetter()
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
        guard let height, height > 20.0 else { return }

        switch type {
        case .add:
            localUser.height = height
            route = .diagnosis(
                withDependencies(from: self) {
                    .init(
                        user: localUser,
                        userCreationFlowEnded: self.userCreationFlowEnded
                    )
                }
            )
        case .edit(let initialUser):
            var updatedUser = initialUser
            updatedUser.height = height
            updateUser(updatedUser)
        }
    }
}

public struct HeightSelectionView: View {
    @ObservedObject var vm: HeightSelectionViewModel
    @FocusState private var isFocused: Bool
    @EnvironmentObject var localizations: ObservableLocalizations

    public init (
        vm: HeightSelectionViewModel
    ) {
        self.vm = vm
    }
    public var body: some View {
        VStack(spacing: 16) {
            if case HeightSelectionViewModel.ActionType.add = vm.type {
                Text(localizations.userCreationSection.heightSelectionTitle)
                    .font(.largeInput)
            }

            Text(localizations.userCreationSection.heightSelectionInfo)
                .padding(.horizontal, 16)
                .font(.body1)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            TextField(
                "Height",
                value: $vm.height,
                format: .number,
                prompt: Text(localizations.userCreationSection.heightTFPrompt).foregroundColor(.gray)
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
            case: /HeightSelectionViewModel.Destination.diagnosis
        ) { $diagnosisIdentityVm in
            DiagnosisView(vm: diagnosisIdentityVm)
        }
    }
}
