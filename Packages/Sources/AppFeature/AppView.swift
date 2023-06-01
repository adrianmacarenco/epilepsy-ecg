//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 27/05/2023.
//

import Foundation
import Combine
import SwiftUI
import DBClient
import Dependencies
import PersistenceClient
import Model
import UserCreation
import HomeTabbar
import SwiftUINavigation

public class AppViewModel: ObservableObject {
    public enum Destination {
        case userCreation(GettingStartedViewModel)
        case home(HomeTabbarViewModel)
    }
    @Published var route: Destination?
    @Dependency (\.dbClient) var dbClient
    @Dependency (\.persistenceClient) var persistenceClient
    
    // MARK: - Public interface
    public init() {
//        Task {
//            try await dbClient.deleteCurrentDb()
//            persistenceClient.user.save(nil)
//        }
        if let user = persistenceClient.user.load() {
            Task {
                do {
                    _ = try await dbClient.getUser(user.id)
                    await MainActor.run { [weak self] in
                        self?.presentHomeScreen()
                    }
                } catch {
                    print("Error fetching the user")
                    await MainActor.run { [weak self] in
                        self?.presentUserCretionFlow()
                    }
                }
            }
        } else {
            presentUserCretionFlow()
        }
    }
    
    func onAppear() {
        
    }
    
    // MARK: - Private interface
    func userCreationFlowEnded() {
        if let user = persistenceClient.user.load() {
            Task {
                do {
                    _ = try await dbClient.getUser(user.id)
                    await MainActor.run { [weak self] in
                        self?.presentHomeScreen()
                    }
                } catch {
                    print("Error fetching the user")
                }
            }
        }
    }
    
    func onConfirmUserDeletion() {
        persistenceClient.user.save(nil)
        persistenceClient.deviceNameSerial.save(nil)
        persistenceClient.deviceConfigurations.save(nil)
        persistenceClient.ecgConfiguration.save(nil)
        persistenceClient.medications.save(nil)
        persistenceClient.medicationIntakes.save(nil)
        Task {
            try await dbClient.clearDb()
            await MainActor.run { [weak self] in
                self?.presentUserCretionFlow()
            }
        }
    }
    
    func presentHomeScreen() {
        self.route = .home(
            withDependencies(from: self) {
                HomeTabbarViewModel(onConfirmProfileDeletion: { [weak self] in self?.onConfirmUserDeletion() })
            }
        )
    }
    
    func presentUserCretionFlow() {
        self.route = .userCreation(
            withDependencies(from: self) {
                GettingStartedViewModel(userCreationFlowEnded: { [weak self] in self?.userCreationFlowEnded() })
            }
        )
    }
}

public struct AppView: View {
    @ObservedObject var vm: AppViewModel
    
    public init(
        vm: AppViewModel
    ) {
        self.vm = vm
    }
    
    public var body: some View {
        IfLet($vm.route) { $destination in
            Switch($destination) {
                CaseLet(/AppViewModel.Destination.userCreation) { $userCreationVm in
                    GettingStartedView(vm: userCreationVm)
                    
                }
                CaseLet(/AppViewModel.Destination.home) { $homeViewModel in
                    HomeTabbarView(vm: homeViewModel)
                }
            }
        }
    }
}
