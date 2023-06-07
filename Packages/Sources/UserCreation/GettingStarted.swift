//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 22/05/2023.
//

import Foundation
import SwiftUI
import StylePackage
import Combine
import Model
import SwiftUINavigation
import Dependencies
import DBClient
import PersistenceClient
import XCTestDynamicOverlay

public class GettingStartedViewModel: ObservableObject {
    enum Destination {
        case personalIdentity(PersonalIdentityViewModel)
    }
    @Published var route: Destination?
    @Dependency (\.dbClient) var dbClient
    @Dependency (\.persistenceClient) var persistenceClient
    var userCreationFlowEnded: () -> Void = unimplemented("DeviceInfoViewModel.onConfirmDeletion")
    let localUser = User(
        id: UUID().uuidString,
        fullName: nil,
        birthday: nil,
        gender: nil,
        weight: nil,
        height: nil,
        diagnosis: nil
    )
    public init(
        userCreationFlowEnded: @escaping() -> Void
    ) {
        self.userCreationFlowEnded = userCreationFlowEnded
    }
    
    func startButtonTapped() {
        route = .personalIdentity(
            withDependencies(from: self) {
                .init(
                    user: localUser,
                    userCreationFlowEnded: self.userCreationFlowEnded
                )
            }
        )
    }
    
    func skipButtonTapped() {
        Task {
            let savedUser = try await dbClient.createUser(localUser.id, localUser.fullName, localUser.birthday, localUser.gender, localUser.weight, localUser.height, localUser.diagnosis)
            persistenceClient.user.save(savedUser)
            userCreationFlowEnded()
        }
    }
}

public struct GettingStartedView: View {
    @ObservedObject var vm: GettingStartedViewModel
    
    public init (
        vm: GettingStartedViewModel
    ) {
        self.vm = vm
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image.gettingStarted
                Text("Getting started")
                    .font(.largeInput)
                Text("Hey there! For the best results, we'll need you to provide some personal information. Rest assured, this data is strictly confidential and will only be used to enhance your experience within the app. Your privacy is our top priority, and we're committed to keeping your information safe and secure.")
                    .padding(.horizontal, 16)
                    .font(.body1)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                Spacer()
                Button("Start", action: vm.startButtonTapped)
                    .buttonStyle(MyButtonStyle.init(style: .primary))
                    .padding(.bottom, 58)
            }
            .padding(.horizontal, 16)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
            .background(Color.background)
            .navigationDestination(
                unwrapping: self.$vm.route,
                case: /GettingStartedViewModel.Destination.personalIdentity
            ) { $personalIdentityVm in
                PersonalIdentityView(vm: personalIdentityVm)
                    .navigationBarTitleDisplayMode(.inline)

            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Set up later") {
                        vm.skipButtonTapped()
                    }
                }
            }
            
        }
        .tint(.tint1)
    }
}

//struct GettingStartedView_Preview: PreviewProvider {
//    static var previews: some View {
//        registerFonts()
//        return GettingStartedView()
//    }
//}
