//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 15/06/2023.
//

import Foundation
import Combine

@dynamicMemberLookup
public class ObservableLocalizations: ObservableObject {
    @Published private var _localizations: Localizations = .englishBundled
    
    public init(_ translations: Localizations) {
        self._localizations = translations
    }

    public subscript<Section>(dynamicMember keyPath: KeyPath<Localizations, Section>) -> Section {
        _localizations[keyPath: keyPath]
    }

    public func updateLocalizations(_ localizations: Localizations) {
        self._localizations = localizations
    }
    
    public func updateLocalization(with type: LanguageType) {
        let fileName = "Localizations_\(type.rawValue)-DK"
        DispatchQueue.main.async {
            self._localizations = loadTranslationsFromJSON(fileName, in: .myModule)
        }

    }
    
    public enum LanguageType: String {
        case da
        case en
    }
}


extension Localizations {
    public static var englishBundled: Localizations = loadTranslationsFromJSON(
        "Localizations_en-DK", in: .myModule)
    public static var danishBundled: Localizations = loadTranslationsFromJSON(
        "Localizations_da-DK", in: .myModule)
}

extension ObservableLocalizations {
    public static func getBundledLocalizations(for languageType: LanguageType) -> ObservableLocalizations {
        switch languageType {
        case .da:
            return ObservableLocalizations(.danishBundled)
        case .en:
            return ObservableLocalizations(.englishBundled)
        }
    }
}

class CurrentBundleFinder {}
extension Foundation.Bundle {
    static var myModule: Bundle = {
        //         The name of your local package, prepended by "LocalPackages_"
        let bundleName = "Packages_Localizations"
        let candidates = [
            //             Bundle should be present here when the package is linked into an App.
            Bundle.main.resourceURL,
            //             Bundle should be present here when the package is linked into a framework.
            Bundle(for: CurrentBundleFinder.self).resourceURL,
            //             For command-line tools.
            Bundle.main.bundleURL,
            //             Bundle should be present here when running previews from a different package (this is the path to "…/Debug-iphonesimulator/").
            Bundle(for: CurrentBundleFinder.self).resourceURL?.deletingLastPathComponent()
                .deletingLastPathComponent(),
        ]
        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }
        }
        fatalError("unable to find bundle named \(bundleName)")
    }()
}
