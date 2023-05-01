//
//  Epilepsy_ECGApp.swift
//  Epilepsy ECG
//
//  Created by Adrian Macarenco on 05/03/2023.
//

import SwiftUI
import ScanDevices
import StylePackage

@main
struct Epilepsy_ECGApp: App {
    init() {
        StylePackage.registerFonts()
    }
    var body: some Scene {
        WindowGroup {
//            HomeView(viewModel: .init())
            ScanDevicesView(viewModel: .init())
        }
    }
}
