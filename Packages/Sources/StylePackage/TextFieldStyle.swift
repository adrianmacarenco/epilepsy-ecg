//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 22/05/2023.
//

import Foundation
import SwiftUI


public struct EcgTextFieldStyle: TextFieldStyle {
    public init(
    ) {
    }
    public func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(10)
            .background(Color.white)
            .cornerRadius(12)
            .foregroundColor(.black)
            .padding(.horizontal, 10)

    }
}
