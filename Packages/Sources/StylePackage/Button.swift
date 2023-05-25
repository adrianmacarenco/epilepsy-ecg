//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 30/04/2023.
//

import Foundation
import SwiftUI

public enum ButtonConfig {
    case primary
}

public extension ButtonConfig {
    var cornerRadius: CGFloat {
        20.0
    }
    
    var backgroundColor: Color {
        switch self {
        case .primary:
            return .tint1
        }
    }
    
    var disabledBackgroundColor: Color {
        return Color.tint2
    }
    
    var titleColor: Color {
        switch self {
        case .primary:
            return Color.white
        }
    }
    
    var disabledTitleColor: Color {
        return .black
    }
    
    var titleFont: Font {
        .title1
    }
}

public struct MyButtonStyle: ButtonStyle {
    let style: ButtonConfig
    let isLoading: Bool
    let isEnabled: Bool

    var textColor: Color {
        if isLoading {
            return .clear
        } else {
            return isEnabled ? style.titleColor : style.disabledTitleColor
        }
    }
    
    public init(
        style: ButtonConfig,
        isLoading: Bool = false,
        isEnabled: Bool = true
    ) {
        self.style = style
        self.isLoading = isLoading
        self.isEnabled = isEnabled
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        ZStack {
            configuration
                .label
                .padding(12)
                .frame(maxWidth: .infinity)
                .font(style.titleFont)
                .foregroundColor(textColor)
        }
        .frame(height: 61)
        .background(isEnabled ? style.backgroundColor : style.disabledBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous))
        .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

public extension ButtonStyle where Self == MyButtonStyle {
    static var primary: MyButtonStyle {
        .init(style: .primary, isLoading: false, isEnabled: true)
    }
}
