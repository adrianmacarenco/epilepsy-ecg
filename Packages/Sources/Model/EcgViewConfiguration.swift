//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 14/05/2023.
//

import Foundation
import SwiftUI
import Charts

public struct EcgConfiguration: Codable {
    public var viewConfiguration: EcgViewConfiguration
    public var frequency: Int
    
    public init(
        viewConfiguration: EcgViewConfiguration,
        frequency: Int
    ) {
        self.viewConfiguration = viewConfiguration
        self.frequency = frequency
    }
}

public struct EcgViewConfiguration: Codable {
    public var lineWidth: Double
    public var chartColor: Color
    public var timeInterval: Double
    
    public init(
        lineWidth: Double,
        chartColor: Color,
        timeInterval: Double
    ) {
        self.lineWidth = lineWidth
        self.chartColor = chartColor
        self.timeInterval = timeInterval
    }
}

public extension Color {
    typealias SystemColor = UIColor
    
    var colorComponents: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        
        guard SystemColor(self).getRed(&r, green: &g, blue: &b, alpha: &a) else {
            // Pay attention that the color should be convertible into RGB format
            // Colors using hue, saturation and brightness won't work
            return nil
        }
        
        return (r, g, b, a)
    }
}

extension Color: Codable {
    enum CodingKeys: String, CodingKey {
        case red, green, blue
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let r = try container.decode(Double.self, forKey: .red)
        let g = try container.decode(Double.self, forKey: .green)
        let b = try container.decode(Double.self, forKey: .blue)
        
        self.init(red: r, green: g, blue: b)
    }

    public func encode(to encoder: Encoder) throws {
        guard let colorComponents = self.colorComponents else {
            return
        }
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(colorComponents.red, forKey: .red)
        try container.encode(colorComponents.green, forKey: .green)
        try container.encode(colorComponents.blue, forKey: .blue)
    }
}

public extension EcgConfiguration {
    static var defaultValue: Self = .init(
        viewConfiguration: .init(
            lineWidth: 1.0,
            chartColor: .pink,
            timeInterval: 4.0
        ),
        frequency: 128
    )
}
