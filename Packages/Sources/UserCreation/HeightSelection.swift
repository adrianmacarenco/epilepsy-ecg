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
        guard let height, height > 20.0 else { return }

        switch type {
        case .add:
            localUser.height = height
            route = .diagnosis(
                withDependencies(from: self) {
                    .init(user: localUser)
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

    public init (
        vm: HeightSelectionViewModel
    ) {
        self.vm = vm
    }
    public var body: some View {
        VStack(spacing: 16) {
            if case HeightSelectionViewModel.ActionType.add = vm.type {
                Text("BMI Calculation")
                    .font(.largeInput)
            }

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
