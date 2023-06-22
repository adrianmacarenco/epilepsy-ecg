//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 22/06/2023.
//

import Foundation

public extension String {
    func capitalizedFirstLetter() -> String {
        guard let firstLetter = first else {
            return self
        }
        return String(firstLetter).capitalized + dropFirst()
    }
}
