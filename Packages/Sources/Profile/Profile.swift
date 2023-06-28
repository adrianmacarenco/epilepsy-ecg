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
import LockScreenWidgetGuide
import Onboarding

public class ProfileViewModel: ObservableObject {
    enum Destination {
        case userInformation(UserInformationViewModel)
        case languageSelection(LanguageSelectionViewModel)
        case lockScreenWidget(LockScreenWidgetGuideViewModel)
        case onboarding(OnboardingViewModel)
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
    
    private func presentWidgetGuide() {

        let guideVm = withDependencies(from: self) {
            LockScreenWidgetGuideViewModel { [weak self] in
                self?.route = nil
            }
        }
        route = .lockScreenWidget(guideVm)
    }
    
    private func presentOnboarding() {
        let onboardingVm = withDependencies(from: self) {
            OnboardingViewModel() { [weak self] in
                self?.route = nil
            }
        }
        route = .onboarding(onboardingVm)
    }
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
        case .onboarding:
            presentOnboarding()
        case .permissions:
            break
        case .lockScreenWidget:
            presentWidgetGuide()
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
    
    func closeLockScreenGuide() {
        route = nil
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
                    .sheet(
                        unwrapping: self.$vm.route,
                        case: /ProfileViewModel.Destination.lockScreenWidget
                    ) { $lockScreenWidgetVm in
                        NavigationStack {
                            LockScreenWidgetGuideView(vm: lockScreenWidgetVm)
                                .toolbarBackground(.visible, for: .navigationBar)
                                .toolbarBackground(.white, for: .navigationBar)
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarTrailing) {
                                        Button(localizations.defaultSection.close.capitalizedFirstLetter()) {
                                            vm.closeLockScreenGuide()
                                        }
                                    }
                                }
                        }
                        
                    }
                    .sheet(
                        unwrapping: self.$vm.route,
                        case: /ProfileViewModel.Destination.onboarding
                    ) { $onboardingVm in
                        NavigationStack {
                            OnboardingView(vm: onboardingVm)
                                .toolbarBackground(.visible, for: .navigationBar)
                                .toolbarBackground(.white, for: .navigationBar)
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarTrailing) {
                                        Button(localizations.defaultSection.close.capitalizedFirstLetter()) {
                                            vm.closeLockScreenGuide()
                                        }
                                    }
                                }
                        }
                        
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
    public enum Components: CaseIterable {
        case acountDetails
        case userInformation
        case termsAndCond
        case appSettings
        case language
        case permissions
        case guides
        case onboarding
        case lockScreenWidget
        
        public func isSection() -> Bool {
            switch self {
            case .acountDetails, .appSettings, .guides:
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
            case .onboarding:
                return profileLozalizations.onboardingTitle
            case .permissions:
                return profileLozalizations.permissionsCellTitle
            case .guides:
                return profileLozalizations.guidesTitle
            case .lockScreenWidget:
                return profileLozalizations.lockScreenWidgetTitle
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
