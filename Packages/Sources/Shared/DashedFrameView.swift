//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 25/05/2023.
//

import Foundation
import SwiftUI
import StylePackage

public struct DashedFrameView: View {
    let title: String
    let tapAction: (() -> Void)?
    
    public init(title: String, tapAction: (() -> Void)? = nil) {
        self.title = title
        self.tapAction = tapAction
    }
    
    public var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Spacer()
            Image.plusIcon
                .foregroundColor(.tint1)
            Text(title)
                .font(.body1)
                .foregroundColor(.tint1)
            Spacer()
            
        }
        .frame(height: 48)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                .foregroundColor(.tint1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture {
            tapAction?()
        }
    }
}
