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
    @Published var user: User?
    @Dependency (\.dbClient) var dbClient
    @Dependency (\.persistenceClient) var persistenceClient
    
    lazy var homeViewModel: HomeTabbarViewModel =  { [weak self] in
        guard let self else { return .init() }
        return withDependencies(from: self) {
            HomeTabbarViewModel()
        }
    }()
    
    lazy var gettingStartedVm: GettingStartedViewModel =  { [weak self] in
        guard let self else { return .init() }
        return withDependencies(from: self) {
            GettingStartedViewModel()
        }
    }()

    // MARK: - Public interface
    public init() {
//        Task {
//            try await dbClient.deleteCurrentDb()
//            persistenceClient.user.save(nil)
//        }
        if let user = persistenceClient.user.load() {
            self.user = user
            Task {
                do {
                    let savedDbUser = try await dbClient.getUser(user.id)
                    print(savedDbUser)
                } catch {
                    print("Error fetching the user")
                }
            }
        }
    }
    
    var userExists: Bool {
        user != nil
    }
    
    func onAppear() {
        
    }
    
    // MARK: - Private interface
    
}

public struct AppView: View {
    @ObservedObject var vm: AppViewModel
    
    public init(
        vm: AppViewModel
    ) {
        self.vm = vm
    }
    
    public var body: some View {
        if vm.userExists {
            HomeTabbarView(vm: vm.homeViewModel)
        } else {
            GettingStartedView(vm: vm.gettingStartedVm)
        }
    }
}
