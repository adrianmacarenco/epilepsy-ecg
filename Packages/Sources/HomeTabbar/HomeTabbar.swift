//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 01/05/2023.
//

import Foundation
import SwiftUI
import Dashboard
import Profile
import StylePackage
import TrackIntake
import Dependencies
import DBClient
import Localizations
import PersistenceClient

public class HomeTabbarViewModel: ObservableObject {
    
    lazy var dashboardVm: DashboardViewModel =  { [weak self] in
        guard let self else { return .init() }
        return withDependencies(from: self) {
            DashboardViewModel()
        }
    }()
    
    lazy var trackIntakeVm: TrackIntakeViewModel =  { [weak self] in
        guard let self else { return .init(type: .add) }
        return withDependencies(from: self) {
            TrackIntakeViewModel(type: .add)
        }
    }()
    
    lazy var profileVm: ProfileViewModel =  { [weak self] in
        guard let self else { return .init(onConfirmProfileDeletion: {}) }
        return withDependencies(from: self) {
            ProfileViewModel(onConfirmProfileDeletion: self.onConfirmProfileDeletion)
        }
    }()
    
    @Dependency (\.dbClient) var dbClient
    @Dependency (\.persistenceClient) var persistenceClient
    var onConfirmProfileDeletion: () -> Void = unimplemented("DeviceInfoViewModel.onConfirmDeletion")

    public init(
        onConfirmProfileDeletion: @escaping () -> Void
    ) {
        self.onConfirmProfileDeletion = onConfirmProfileDeletion
    }
    
    deinit {
        print("Deinitialized 💀")
    }
    
}

public struct HomeTabbarView: View {
    @ObservedObject var vm: HomeTabbarViewModel
    @EnvironmentObject var localizations: ObservableLocalizations

    public init(
        vm: HomeTabbarViewModel
    ) {
        self.vm = vm
    }
    public var body: some View {
        TabView {
            DashboardView(vm: vm.dashboardVm)
                .tabItem {
                    VStack{
                        Image.homeTabIcon
                            .renderingMode(.template)
                        Text(localizations.homeTabbarSection.dashboardTapviewTitle)
                    }
                }
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarBackground(Color.background, for: .tabBar)
            
            TrackIntakeView(vm: vm.trackIntakeVm)
                .tabItem {
                    VStack{
                        Image.tackIntakeTabIcon
                            .renderingMode(.template)
                        Text(localizations.homeTabbarSection.trackIntakeTapviewTitle)
                    }
                }
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarBackground(Color.background, for: .tabBar)
            
            ProfileView(vm: vm.profileVm)
                .tabItem {
                    VStack {
                        Image.profileTabIcon
                            .renderingMode(.template)
                        Text(localizations.homeTabbarSection.profileTapviewTitle)

                    }
                }
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarBackground(Color.background, for: .tabBar)
        }
        .tint(.tint1)
    }
}
