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
import Model
import Dependencies
import DBClient
import PersistenceClient
import Localizations

public class PersonalIdentityViewModel: ObservableObject {
    enum Destination {
        case birthday(UserBirthdayViewModel)
    }
    
    public enum ActionType {
        case add
        case edit(User)
    }
    
    @Published var route: Destination?
    @Published var name = ""
    @Dependency (\.dbClient) var dbClient
    @Dependency (\.persistenceClient) var persistenceClient
    @Dependency (\.localizations) var localizations

    let type: ActionType
    var localUser: User
    let userUpdated: ((User) -> Void)?
    var userCreationFlowEnded: () -> Void

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
        if case let ActionType.edit(initialUser) = type, let initialUserValue = initialUser.fullName {
            name = initialUserValue
        }
    }
    
    var isActionButtonEnabled: Bool {
        switch type {
        case .add:
            return !name.isEmpty && name.count > 2
        case .edit(let initialUser):
            return !name.isEmpty && name.count > 2 && name != initialUser.fullName
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
        guard !name.isEmpty && name.count > 2 else { return }
        
        switch type {
        case .add:
            localUser.fullName = name
            route = .birthday(
                withDependencies(from: self) {
                    .init(
                        user: localUser,
                        userCreationFlowEnded: self.userCreationFlowEnded
                    )
                }
            )
        case .edit(let initialUser):
            var updatedUser = initialUser
            updatedUser.fullName = name
            updateUser(updatedUser)
        }
    }
}

public struct PersonalIdentityView: View {
    @ObservedObject var vm: PersonalIdentityViewModel
    @FocusState private var isFocused: Bool
    @EnvironmentObject var localizations: ObservableLocalizations

    public init (
        vm: PersonalIdentityViewModel
    ) {
        self.vm = vm
    }
    public var body: some View {
        VStack(spacing: 16) {
            if case PersonalIdentityViewModel.ActionType.add = vm.type {
                Text(localizations.userCreationSection.personalIdentitySelectionTitle)
                    .font(.largeInput)
            }
            Text(localizations.userCreationSection.personalIdentitySelectionInfo)
                .padding(.horizontal, 16)
                .font(.body1)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            TextField(
                "Full name",
                text: $vm.name,
                prompt: Text(localizations.userCreationSection.personalIdentityPrompt).foregroundColor(.gray)
            )
            .textFieldStyle(EcgTextFieldStyle())
            .focused($isFocused)
            Spacer()
            Button(vm.actionButtonTitle, action: vm.actionButtonTapped)
                .buttonStyle(MyButtonStyle.init(style: .primary, isEnabled: vm.isActionButtonEnabled))
                .disabled(!vm.isActionButtonEnabled)
                .padding(.bottom, 58)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            self.isFocused = false
        }
        .padding(.horizontal, 16)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
        .background(Color.background)
        .navigationDestination(
            unwrapping: self.$vm.route,
            case: /PersonalIdentityViewModel.Destination.birthday
        ) { $birthdayVm in
            UserBirthdayView(vm: birthdayVm)
        }
    }
}
