//
//  Epilepsy_ECGApp.swift
//  Epilepsy ECG
//
//  Created by Adrian Macarenco on 05/03/2023.
//

import SwiftUI

@main
struct Epilepsy_ECGApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView(viewModel: .init())
        }
    }
}
