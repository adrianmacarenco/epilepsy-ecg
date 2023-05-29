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
    }
    @Published var components = Components.allCases
    @Published var route: Destination?
    @Dependency (\.dbClient) var dbClient
    @Dependency (\.persistenceClient) var persistenceClient
    
    // MARK: - Public Interface
    
    public init() {
        
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
                    
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                .padding(.horizontal, 16)
                .navigationDestination(
                    unwrapping: self.$vm.route,
                    case: /ProfileViewModel.Destination.userInformation
                ) { $userInfoVm in
                    UserInformationView(vm: userInfoVm)
                }
            }
            .background(Color.background)
            .navigationTitle("Profile")
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
