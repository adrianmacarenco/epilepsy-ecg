//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 13/05/2023.
//

import Foundation

public final class Localizations: Codable {
    public let defaultSection: DefaultSection
    
    public final class DefaultSection: Codable {
        public let save: String
    }
}


internal func loadTranslationsFromJSON(_ filename: String, in bundle: Bundle) -> Localizations {
    let path = bundle.path(forResource: filename, ofType: "json")!

    let data = try! String(contentsOfFile: path).data(using: .utf8)!

    let result = try! JSONDecoder().decode(Localizations.self, from: data)
    return result
}
