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

public class HomeTabbarViewModel: ObservableObject {
    lazy var dashboardVm: DashboardViewModel =  { [weak self] in
        guard let self else { return .init() }
        return withDependencies(from: self) {
            DashboardViewModel()
        }
    }()
    
    lazy var trackIntakeVm: TrackIntakeViewModel =  { [weak self] in
        guard let self else { return .init() }
        return withDependencies(from: self) {
            TrackIntakeViewModel()
        }
    }()
    
//    lazy var profileVm: DashboardViewModel =  { [weak self] in
//        guard let self else { return .init() }
//        return withDependencies(from: self) {
//            DashboardViewModel()
//        }
//    }()
    
    public init() {}
}

public struct HomeTabbarView: View {
    @ObservedObject var vm: HomeTabbarViewModel
    
    public init(vm: HomeTabbarViewModel) {
        self.vm = vm
//        UITabBar.appearance().isTranslucent = false
//        UITabBar.appearance().barTintColor = UIColor.blue
    }
    public var body: some View {
        TabView {
            DashboardView(vm: vm.dashboardVm)
                .tabItem {
                    VStack{
                        Image.iconHomeTab
                            .renderingMode(.template)
                        Text("Dashboard")
                    }
                }
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarBackground(Color.background, for: .tabBar)
            TrackIntakeView(vm: vm.trackIntakeVm)
                .tabItem {
                    VStack{
                        Image.pillTab
                            .renderingMode(.template)
                        Text("Track intake")
                    }
                }
            ProfileView()
                .tabItem {
                    VStack {
                        Image.iconProfileTab
                            .renderingMode(.template)
                        Text("Profile")

                    }
                }
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarBackground(Color.background, for: .tabBar)
        }
        .tint(.tint1)
    }
}
