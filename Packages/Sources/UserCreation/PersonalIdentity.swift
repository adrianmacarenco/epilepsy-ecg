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

public class PersonalIdentityViewModel: ObservableObject {
    enum Destination {
        case birthday(UserBirthdayViewModel)
    }
    @Published var route: Destination?
    @Published var name = ""
    var localUser: User
    @Dependency (\.dbClient) var dbClient
    @Dependency (\.persistenceClient) var persistenceClient
    
    public init(user: User) {
        self.localUser = user
    }
    
    var isNextButtonEnabled: Bool {
        !name.isEmpty && name.count > 2
    }
    
    func nextButtonTapped() {
        guard !name.isEmpty && name.count > 2 else { return }
        localUser.fullName = name
        route = .birthday(
            withDependencies(from: self) {
                .init(user: localUser)
            }
        )
    }
}

public struct PersonalIdentityView: View {
    @ObservedObject var vm: PersonalIdentityViewModel
    
    public init (
        vm: PersonalIdentityViewModel
    ) {
        self.vm = vm
    }
    public var body: some View {
        VStack(spacing: 16) {
            Text("Your Personal Identity")
                .font(.largeInput)
            Text("Please enter your full name. This information helps us personalize your experience and ensures that any generated reports or alerts are accurately addressed to you.")
                .padding(.horizontal, 16)
                .font(.body1)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            TextField(
                "Full name",
                text: $vm.name,
                prompt: Text("Type your full name").foregroundColor(.gray)
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
            case: /PersonalIdentityViewModel.Destination.birthday
        ) { $birthdayVm in
            UserBirthdayView(vm: birthdayVm)
        }
    }
}
