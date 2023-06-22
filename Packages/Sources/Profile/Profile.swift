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
import Localizations

public class ProfileViewModel: ObservableObject {
    enum Destination {
        case userInformation(UserInformationViewModel)
        case languageSelection(LanguageSelectionViewModel)
        case alert(AlertState<AlertAction>)
    }
    
    public enum AlertAction {
      case confirmDeletion
    }
    
    @Published var components = Components.allCases
    @Published var route: Destination?
    @Dependency (\.dbClient) var dbClient
    @Dependency (\.persistenceClient) var persistenceClient
    @Dependency (\.localizations) var localizations
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
            var language = "en"
            if let selectedLanguage = persistenceClient.selectedLanguage.load() {
                language = selectedLanguage
            }
            
            route = .languageSelection(
                withDependencies(from: self, operation: {
                    LanguageSelectionViewModel(cachedLanguage: language)
                })
            )
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
        route = .alert(.delete(
            title: localizations.profileSection.deleteProfileAlertTitle,
            message: localizations.profileSection.deleteProfileAlertMessage,
            yesBtntitle: localizations.defaultSection.yes.capitalizedFirstLetter(),
            noBtnAction: localizations.defaultSection.no.capitalizedFirstLetter()
        ))
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
    @EnvironmentObject var localizations: ObservableLocalizations

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
                                Text(vm.components[index].getDescription(profileLozalizations: localizations.profileSection))
                                    .font(.sectionTitle)
                                    .foregroundColor(.sectionTitle)
                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, 16)
                            } else {
                                ProfileCellView(title: vm.components[index].getDescription(profileLozalizations: localizations.profileSection))
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        vm.componentTapped(index: index)
                                    }
                            }
                            
                        }
                        Spacer()
                        Button(localizations.profileSection.deleteProfileBtnTitle, action: vm.deleteProfileTapped)
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
                    .navigationDestination(
                        unwrapping: self.$vm.route,
                        case: /ProfileViewModel.Destination.userInformation
                    ) { $userInfoVm in
                        UserInformationView(vm: userInfoVm)
                    }
                    .navigationDestination(
                        unwrapping: self.$vm.route,
                        case: /ProfileViewModel.Destination.languageSelection
                    ) { $languageSelectionVm in
                        LanguageSelectionView(vm: languageSelectionVm)
                    }
                    .alert(
                      unwrapping: self.$vm.route,
                      case: /ProfileViewModel.Destination.alert
                    ) { action in
                      self.vm.alertButtonTapped(action)
                    }
                }
                .background(Color.background)
                .navigationTitle(localizations.profileSection.profileTitle)
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
        
        public func getDescription(profileLozalizations: Localizations.ProfileSection) -> String {
            switch self {
            case .acountDetails:
                return profileLozalizations.accountDetailsCellTitle
            case .userInformation:
                return profileLozalizations.userInformationCellTitle
            case .termsAndCond:
                return profileLozalizations.termsAndCondCellTitle
            case .appSettings:
                return profileLozalizations.appSettingsCellTitle
            case .language:
                return profileLozalizations.languageCellTitle
            case .help:
                return profileLozalizations.helpCellTitle
            case .permissions:
                return profileLozalizations.permissionsCellTitle
            case .voiceControl:
                return profileLozalizations.voiceControlCellTitle
            case .siriShortcuts:
                return profileLozalizations.siriShortcutsCellTitle
            }
        }
    }
}


extension AlertState where Action == ProfileViewModel.AlertAction {
    static func delete(
        title: String,
        message:String,
        yesBtntitle: String,
        noBtnAction: String
    ) -> Self {
        AlertState(
        title: TextState(title),
        message: TextState(message),
        buttons: [
          .destructive(TextState(yesBtntitle), action: .send(.confirmDeletion)),
          .cancel(TextState(noBtnAction))
        ]
      )
    }
}
