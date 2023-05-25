//
//  Epilepsy_ECGApp.swift
//  Epilepsy ECG
//
//  Created by Adrian Macarenco on 05/03/2023.
//

import SwiftUI
import StylePackage
import HomeTabbar
import UserCreation

@main
struct Epilepsy_ECGApp: App {
    init() {
        StylePackage.registerFonts()
    }
    var body: some Scene {
        WindowGroup {
//            HomeView(viewModel: .init())
//            HomeTabbarView()
            GettingStartedView(vm: .init())
        }
    }
}
