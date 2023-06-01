//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 01/05/2023.
//

import Foundation
import SwiftUI
import StylePackage
import Model
import DBClient
import PersistenceClient
import Dependencies
import UserInformation
import SwiftUINavigation

public class ProfileViewModel: ObservableObject {
    enum Destination {
        case userInformation(UserInformationViewModel)
        case alert(AlertState<AlertAction>)
    }
    
    public enum AlertAction {
      case confirmDeletion
    }
    
    @Published var components = Components.allCases
    @Published var route: Destination?
    @Dependency (\.dbClient) var dbClient
    @Dependency (\.persistenceClient) var persistenceClient
    var onConfirmProfileDeletion: () -> Void = unimplemented("DeviceInfoViewModel.onConfirmDeletion")

    // MARK: - Public Interface
    
    public init(
        onConfirmProfileDeletion: @escaping () -> Void
    ) {
        self.onConfirmProfileDeletion = onConfirmProfileDeletion
    }
    
    func task() async {
        
    }
    
    // MARK: - Prive Interface
    
    
    // MARK: - Actions
    func componentTapped(index: Int) {
        guard index < components.count else { return }
        switch components[index] {
        case .userInformation:
            guard let user = persistenceClient.user.load() else { return }
            
            route = .userInformation(
                withDependencies(from: self, operation: {
                    UserInformationViewModel(user: user)
                })
            )
        case .termsAndCond:
            break
        case .language:
            break
        case .help:
            break
        case .permissions:
            break
        case .siriShortcuts:
            break
        default:
            break
        }
    }
    
    func deleteProfileTapped() {
        route = .alert(.delete)
    }
    
    func alertButtonTapped(_ action: AlertAction) {
      switch action {
      case .confirmDeletion:
        self.onConfirmProfileDeletion()
      }
    }
}

public struct ProfileView: View {
    
    @ObservedObject var vm: ProfileViewModel
    
    public init(
        vm: ProfileViewModel
    ) {
        self.vm = vm
    }
    
    public var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(0 ..< vm.components.count, id: \.self) { index in
                            if vm.components[index].isSection() {
                                Text(vm.components[index].rawValue)
                                    .font(.sectionTitle)
                                    .foregroundColor(.sectionTitle)
                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, 16)
                            } else {
                                ProfileCellView(title: vm.components[index].rawValue)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        vm.componentTapped(index: index)
                                    }
                            }
                            
                        }
                        Spacer()
                        Button("Delete profile", action: vm.deleteProfileTapped)
                            .buttonStyle(MyButtonStyle.init(style: .delete))
                            .padding(.bottom, 24)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                    .frame(height: geometry.size.height)
                    .padding(.horizontal, 16)
                    .navigationDestination(
                        unwrapping: self.$vm.route,
                        case: /ProfileViewModel.Destination.userInformation
                    ) { $userInfoVm in
                        UserInformationView(vm: userInfoVm)
                    }
                    .alert(
                      unwrapping: self.$vm.route,
                      case: /ProfileViewModel.Destination.alert
                    ) { action in
                      self.vm.alertButtonTapped(action)
                    }
                }
                .background(Color.background)
                .navigationTitle("Profile")
            }
        }
    }
}


extension ProfileViewModel {
    public enum Components: String, CaseIterable {
        case acountDetails = "Acount details"
        case userInformation = "User information"
        case termsAndCond = "Terms and conditions"
        case appSettings = "App settings"
        case language = "Language"
        case help = "Help"
        case permissions = "Permissions"
        case voiceControl = "Voice control"
        case siriShortcuts = "Siri shortcuts"
        
        public func isSection() -> Bool {
            switch self {
            case .acountDetails, .appSettings, .voiceControl:
                return true
            default:
                return false
            }
        }
    }
}


extension AlertState where Action == ProfileViewModel.AlertAction {
  static let delete = AlertState(
    title: TextState("Delete profile"),
    message: TextState("Are you sure you want to delete this profile?"),
    buttons: [
      .destructive(TextState("Yes"), action: .send(.confirmDeletion)),
      .cancel(TextState("No"))
    ]
  )
}
