//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 21/05/2023.
//

import Foundation
import SwiftUI

public struct LoadingView: View {
    @State private var isRotating = false
    
    private let gradient = AngularGradient(
        gradient: Gradient(colors: [Color.tint1, .white]),
        center: .center,
        startAngle: .degrees(270),
        endAngle: .degrees(0))
    
    public init(isRotating: Bool = false) {
        self.isRotating = isRotating
    }
    
    public var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white, lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: CGFloat(0.8))
                .stroke(gradient, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(isRotating ? 360 : 0))
                .animation(Animation.linear(duration: 1.0).repeatForever(autoreverses: false))
        }
        .onAppear {
            isRotating = true
        }
    }
}



struct CircularGradientLine_Preview: PreviewProvider {
    static var previews: some View {
        LoadingView(isRotating: true)
    }
}
