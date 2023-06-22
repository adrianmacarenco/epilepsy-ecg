//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 15/06/2023.
//

import Foundation
import Dependencies

extension ObservableLocalizations: TestDependencyKey {
    public static var testValue: ObservableLocalizations {
        .getBundledLocalizations(for: .en)
    }
}

public extension DependencyValues {
    var localizations: ObservableLocalizations {
        get { self[ObservableLocalizations.self] }
        set { self[ObservableLocalizations.self] = newValue }
    }
}
