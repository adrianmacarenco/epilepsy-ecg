//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 30/04/2023.
//

import Foundation
import class Foundation.Bundle
import class Foundation.ProcessInfo
import struct Foundation.URL
//
private class BundleFinder {}

extension Foundation.Bundle {
    /// Returns the resource bundle associated with the current Swift module.
    static var myModule: Bundle = {
        let bundleName = "Packages_StylePackage"

        let overrides: [URL]
        #if DEBUG
        if let override = ProcessInfo.processInfo.environment["PACKAGE_RESOURCE_BUNDLE_URL"] {
            overrides = [URL(fileURLWithPath: override)]
        } else {
            overrides = []
        }
        #else
        overrides = []
        #endif

        let candidates = overrides + [
            //             Bundle should be present here when the package is linked into an App.
            Bundle.main.resourceURL,
            //             Bundle should be present here when the package is linked into a framework.
            Bundle(for: BundleFinder.self).resourceURL,
            //             For command-line tools.
            Bundle.main.bundleURL,
            //             Bundle should be present here when running previews from a different package (this is the path to "…/Debug-iphonesimulator/").
            Bundle(for: BundleFinder.self).resourceURL?.deletingLastPathComponent()
                .deletingLastPathComponent(),
        ]

        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }
        }
        fatalError("unable to find bundle named Packages_StylePackage")
    }()
}
