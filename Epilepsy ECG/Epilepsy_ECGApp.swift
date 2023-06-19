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
import AppFeature
import Localizations
import Dependencies

@main
struct Epilepsy_ECGApp: App {
    @Dependency(\.localizations) var localizations

    init() {
        StylePackage.registerFonts()
    }
    var body: some Scene {
        WindowGroup {
            AppView(vm: .init())
                .environmentObject(localizations)
        }
    }
}
