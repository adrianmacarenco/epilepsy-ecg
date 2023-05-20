//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 20/05/2023.
//

import Foundation

public extension Array where Element == Int32 {
    func commaSeparatedString() -> String {
        self.map { String($0) }.joined(separator: ",")
    }
}
