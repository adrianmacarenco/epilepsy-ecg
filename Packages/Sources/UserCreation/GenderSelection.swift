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

public class GenderSelectionViewModel: ObservableObject {
    enum Destination {
        case weightSelection(WeightSelectionViewModel)
    }
    
    public enum ActionType {
        case add
        case edit(User)
    }
    @Published var route: Destination?
    @Published var selectedGender: String = ""
    @Dependency (\.dbClient) var dbClient
    @Dependency (\.persistenceClient) var persistenceClient
    let type: ActionType
    var genders = ["Male", "Female"]
    
    var oldestPersonAlive: Date {
            let calendar = Calendar.current
            let currentDate = Date()
            let oldestDateComponents = DateComponents(year: calendar.component(.year, from: currentDate) - 10)
            return calendar.date(from: oldestDateComponents)!
        }
    
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
            selectedGender = initialUser.gender
        }
    }
    
    var isActionButtonEnabled: Bool {
        guard !selectedGender.isEmpty else { return false }
        switch type {
        case .add:
            return true
        case .edit(let initialUser):
            return selectedGender != initialUser.gender
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
        guard genders.contains(selectedGender) else { return }

        switch type {
        case .add:
            localUser.gender = selectedGender
            route = .weightSelection(
                withDependencies(from: self) {
                    .init(
                        user: localUser,
                        userCreationFlowEnded: self.userCreationFlowEnded
                    )
                }
            )
        case .edit(let initialUser):
            var updatedUser = initialUser
            updatedUser.gender = selectedGender
            updateUser(updatedUser)
        }
    }
    
    func didTapGenderCell(_ index: Int) {
        guard index < genders.count else { return }
        selectedGender = genders[index]
    }

}

public struct GenderSelectionView: View {
    @ObservedObject var vm: GenderSelectionViewModel
    
    public init (
        vm: GenderSelectionViewModel
    ) {
        self.vm = vm
    }
    public var body: some View {
        VStack(spacing: 16) {
            if case GenderSelectionViewModel.ActionType.add = vm.type {
                Image.genderIcon
                Text("Gender-specific Factors")
                    .font(.largeInput)
            }
            Text("Please select your gender. This information helps us consider any gender-specific factors that may impact your heart health and epilepsy management.")
                .padding(.horizontal, 16)
                .font(.body1)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            ForEach(0 ..< vm.genders.count, id: \.self) { index in
                GenderCell(
                    title: vm.genders[index],
                    vm: .init(isSelected: vm.selectedGender == vm.genders[index])
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    vm.didTapGenderCell(index)
                }
            }
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
            case: /GenderSelectionViewModel.Destination.weightSelection
        ) { $weightSelectionVm in
            WeightSelectionView(vm: weightSelectionVm)
        }
    }
}


class GenderCellViewModel: ObservableObject {
    @Published var isSelected: Bool
    
    init(isSelected: Bool) {
        self.isSelected = isSelected
    }
}
struct GenderCell: View {
    let title: String
    @ObservedObject var vm: GenderCellViewModel
    
    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .font(.title1)
                    .foregroundColor(.black)
                Spacer()
                if vm.isSelected {
                    Image.checkedIcon
                } else {
                    Circle()
                        .stroke(Color.separator, lineWidth: 1)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.all, 16)
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
        .background(vm.isSelected ? Color.background2 : Color.clear)
        .cornerRadius(8)
        .overlay(
            vm.isSelected ? nil : RoundedRectangle(cornerRadius: 8).stroke(Color.separator, lineWidth: 1)
        )
    }
}
