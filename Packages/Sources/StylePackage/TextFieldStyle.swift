//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 22/05/2023.
//

import Foundation
import SwiftUI


public struct EcgTextFieldStyle: TextFieldStyle {
    let image: Image?
    let description: String?
    let padding: CGFloat?
    
    public init(
        description: String? = nil,
        padding: CGFloat? = nil,
        @ViewBuilder _ content: (() -> Image)
    ) {
        self.image = content()
        self.description = description
        self.padding = padding
    }
    
    public init(
        description: String? = nil
    ) {
        self.description = description
        self.image = nil
        self.padding = nil
    }
    
    public func _body(configuration: TextField<Self._Label>) -> some View {
        HStack {
            if let image {
                image
            }
            configuration
            if let description {
                Text(description)
            }
            
        }
        .padding(.horizontal, 10)
        .padding(.vertical, self.padding ?? 10)
        .background(Color.white)
        .cornerRadius(8)
        .foregroundColor(.black)        
    }
}
