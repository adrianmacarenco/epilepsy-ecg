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

public struct HomeTabbarView: View {
    public init() {
//        UITabBar.appearance().isTranslucent = false
//        UITabBar.appearance().barTintColor = UIColor.blue
    }
    public var body: some View {
        TabView {
            DashboardView(vm: .init())
                .tabItem {
                    VStack{
                        Image.iconHomeTab
                            .renderingMode(.template)
                        Text("Dashboard")
                    }
                }
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarBackground(Color.background, for: .tabBar)
            ProfileView()
                .tabItem {
                    VStack {
                        Image.iconProfileTab
                            .renderingMode(.template)
                        Text("Profile")
                            .foregroundColor(.red)

                    }

                }
        }
        .tint(.tint1)

    }
}
