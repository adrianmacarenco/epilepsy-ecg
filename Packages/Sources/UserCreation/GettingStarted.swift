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
import Localizations

public class GettingStartedViewModel: ObservableObject {
    enum Destination {
        case personalIdentity(PersonalIdentityViewModel)
        case alert(AlertState<AlertAction>)
    }
    
    public enum AlertAction {
      case confirmSetUpLater
    }
    
    @Published var route: Destination?
    @Dependency (\.dbClient) var dbClient
    @Dependency (\.persistenceClient) var persistenceClient
    @Dependency (\.localizations) var localizations

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
        route = .alert(.setUpLater(
            title: localizations.userCreationSection.setupLaterAlertTitle,
            message: localizations.userCreationSection.setupLaterAlertMessage,
            yesBtnTitle: localizations.defaultSection.yes.capitalizedFirstLetter(),
            notBtnTitle: localizations.defaultSection.no.capitalizedFirstLetter()))
    }
    func alertButtonTapped(_ action: AlertAction) {
      switch action {
      case .confirmSetUpLater:
          Task {
              let savedUser = try await dbClient.createUser(localUser.id, localUser.fullName, localUser.birthday, localUser.gender, localUser.weight, localUser.height, localUser.diagnosis)
              persistenceClient.user.save(savedUser)
              userCreationFlowEnded()
          }
      }
    }
}

public struct GettingStartedView: View {
    @ObservedObject var vm: GettingStartedViewModel
    @EnvironmentObject var localizations: ObservableLocalizations

    public init (
        vm: GettingStartedViewModel
    ) {
        self.vm = vm
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image.gettingStarted
                Text(localizations.userCreationSection.gettingStartedTitle)
                    .font(.largeInput)
                Text(localizations.userCreationSection.gettingStartedInfo)
                    .padding(.horizontal, 16)
                    .font(.body1)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                Spacer()
                Button(localizations.defaultSection.start.capitalizedFirstLetter(), action: vm.startButtonTapped)
                    .buttonStyle(MyButtonStyle.init(style: .primary))
                    .padding(.bottom, 58)
            }
            .padding(.horizontal, 16)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
            .background(Color.background)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizations.userCreationSection.setupLaterBtnTitle) {
                        vm.skipButtonTapped()
                    }
                }
            }
            .navigationDestination(
                unwrapping: self.$vm.route,
                case: /GettingStartedViewModel.Destination.personalIdentity
            ) { $personalIdentityVm in
                PersonalIdentityView(vm: personalIdentityVm)
                    .navigationBarTitleDisplayMode(.inline)

            }
            .alert(
              unwrapping: self.$vm.route,
              case: /GettingStartedViewModel.Destination.alert
            ) { action in
              self.vm.alertButtonTapped(action)
            }
        }
        .tint(.tint1)
    }
}

extension AlertState where Action == GettingStartedViewModel.AlertAction {
    static func setUpLater(title: String, message: String, yesBtnTitle: String, notBtnTitle: String) -> AlertState {
        AlertState(
            title: TextState(title),
            message: TextState(message),
            buttons: [
                .destructive(TextState(yesBtnTitle), action: .send(.confirmSetUpLater)),
                .cancel(TextState(notBtnTitle))
            ]
        )
    }
}
