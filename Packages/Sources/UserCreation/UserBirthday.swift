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
    
    let type: ActionType
    var localUser: User
    let userUpdated: ((User) -> Void)?
    let now = Date()
    
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
            birthdayDate = initialUser.birthday
        }
    }
    
    var isActionButtonEnabled: Bool {
        guard let birthdayDate else { return false }
        switch type {
        case .add:
            return birthdayDate < now
        case .edit(let initialUser):
            return birthdayDate < now && !birthdayDate.isSameDay(as: initialUser.birthday)
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
        guard let birthdayDate else { return }
        switch type {
        case .add:
            localUser.birthday = birthdayDate
            route = .genderSelection(
                withDependencies(from: self) {
                    .init(user: localUser)
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
    
    public init (
        vm: UserBirthdayViewModel
    ) {
        self.vm = vm
    }
    public var body: some View {
        VStack(spacing: 16) {
            if vm.isAddAction {
                Text("Age Calculation")
                    .font(.largeInput)
            }
            Text("Please provide your date of birth. This information allows us to calculate your age, which is important for tailoring your heart monitoring and seizure management recommendations.")
                .padding(.horizontal, 16)
                .font(.body1)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            DatePicker(
                "Select your birthday",
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

