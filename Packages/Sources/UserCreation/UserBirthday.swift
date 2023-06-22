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
import Model
import SwiftUINavigation
import Dependencies
import DBClient
import PersistenceClient
import Shared
import XCTestDynamicOverlay
import Localizations

public class UserBirthdayViewModel: ObservableObject {
    enum Destination {
        case genderSelection(GenderSelectionViewModel)
    }
    public enum ActionType {
        case add
        case edit(User)
    }
    @Published var route: Destination?
    @Published var birthdayDate: Date?
    @Dependency (\.dbClient) var dbClient
    @Dependency (\.persistenceClient) var persistenceClient
    @Dependency (\.localizations) var localizations

    let type: ActionType
    var localUser: User
    let now = Date()
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
            birthdayDate = initialUser.birthday
        }
    }
    
    var isActionButtonEnabled: Bool {
        guard let birthdayDate else { return false }
        switch type {
        case .add:
            return birthdayDate < now
        case .edit(let initialUser):
            guard let initialUserBirthday = initialUser.birthday else { return false }
            return birthdayDate < now && !birthdayDate.isSameDay(as: initialUserBirthday)
        }
    }
    
    var isAddAction: Bool {
        switch type {
        case .add:
            return true
        default:
            return false
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
        guard let birthdayDate else { return }
        switch type {
        case .add:
            localUser.birthday = birthdayDate
            route = .genderSelection(
                withDependencies(from: self) {
                    .init(
                        user: localUser,
                        userCreationFlowEnded: self.userCreationFlowEnded
                    )
                }
            )
        case .edit(let initialUser):
            var updatedUser = initialUser
            updatedUser.birthday = birthdayDate
            updateUser(updatedUser)
        }
    }
    
    func setBirthday(_ date: Date) {
        self.birthdayDate = date
    }

}

public struct UserBirthdayView: View {
    @ObservedObject var vm: UserBirthdayViewModel
    @EnvironmentObject var localizations: ObservableLocalizations

    public init (
        vm: UserBirthdayViewModel
    ) {
        self.vm = vm
    }
    public var body: some View {
        VStack(spacing: 16) {
            if vm.isAddAction {
                Text(localizations.userCreationSection.birthdaySelectionSelectionTitle)
                    .font(.largeInput)
            }
            Text(localizations.userCreationSection.birthdaySelectionSelectionInfo)
                .padding(.horizontal, 16)
                .font(.body1)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            DatePicker(
                localizations.userCreationSection.birthdaySelectionIdentityPrompt,
                selection: Binding<Date>.init(
                    get: { vm.birthdayDate ?? Date() },
                    set: vm.setBirthday(_:)),
                in: Date.oldestPersonAlive ... vm.now,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .background(Color.white)
            .cornerRadius(13)
            .tint(.tint1)
            Spacer()
            Button(vm.actionButtonTitle, action: vm.actionButtonTapped)
                .buttonStyle(MyButtonStyle.init(style: .primary, isEnabled: vm.isActionButtonEnabled))
                .padding(.bottom, 58)
                .disabled(!vm.isActionButtonEnabled)
        }
        .padding(.horizontal, 16)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
        .background(Color.background)
        .navigationDestination(
            unwrapping: self.$vm.route,
            case: /UserBirthdayViewModel.Destination.genderSelection
        ) { $genderSelectionVm in
            GenderSelectionView(vm: genderSelectionVm)
        }
    }
}

