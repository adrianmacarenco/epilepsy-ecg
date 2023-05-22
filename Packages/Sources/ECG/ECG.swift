//
//  File.swift
//
//
//  Created by Adrian Macarenco on 12/05/2023.
//

import Foundation
import SwiftUI
import Combine
import Charts
import StylePackage
import Model
import Dependencies

public enum Constants {
    static let previewChartHeight: CGFloat = 100
    static let detailChartHeight: CGFloat = 300
}

public struct EcgViewModel {
    public var data: [Double]
    public var configuration: EcgConfiguration
    public var scaleFactor = 1.0
    public var avrHr: Int = 0
    @Dependency (\.continuousClock) var clock

    public init(
        data: [Double],
        ecgConfig: EcgConfiguration,
        configurationDidChange: @escaping(EcgConfiguration) -> () = { _ in}
    ) {
        self.data = data
        self.configuration = ecgConfig
    }
    
    var desiredInterval: Int {
        Int(configuration.viewConfiguration.timeInterval)
    }
}

public struct EcgView: View {
    @Binding var stateModel: EcgViewModel
    var computeTime: (Int, Int) -> Double
    
    public init(
        model: Binding<EcgViewModel>,
        computeTime: @escaping(Int, Int) -> Double
    ) {
        self._stateModel = model
        self.computeTime = computeTime
    }
    
    public var body: some View {
        VStack (spacing: 16) {
            Chart {
                ForEach((0 ..< stateModel.data.count), id: \.self) { index in
                    LineMark(
                        x: .value("Seconds", computeTime(index, stateModel.desiredInterval)),
                        y: .value("Unit", stateModel.data[index])
                    )
                    .lineStyle(StrokeStyle(lineWidth: stateModel.configuration.viewConfiguration.lineWidth))
                    .foregroundStyle(stateModel.configuration.viewConfiguration.chartColor)
                    .interpolationMethod(.cardinal)
                    .accessibilityLabel("\(stateModel.configuration.viewConfiguration.timeInterval)s")
                    .accessibilityValue("\(stateModel.data[index]) mV")
                    .accessibilityHidden(false)
                }
            }
            .frame(height: Constants.detailChartHeight)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: stateModel.desiredInterval)) { value in
                    if let doubleValue = value.as(Double.self),
                       let intValue = value.as(Int.self) {
                        if doubleValue - Double(intValue) == 0 {
                            AxisTick(stroke: .init(lineWidth: 1))
                                .foregroundStyle(.gray)
                            AxisValueLabel() {
                                Text("\(intValue)s")
                                    .foregroundColor(.black)
                            }
                            AxisGridLine(stroke: .init(lineWidth: 1))
                                .foregroundStyle(.gray)
                        } else {
                            AxisGridLine(stroke: .init(lineWidth: 1))
                                .foregroundStyle(.gray.opacity(0.25))
                        }
                    }
                }
            }
            .chartYScale(domain: -7000...7000)
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 14)) { value in
                    AxisGridLine(stroke: .init(lineWidth: 1))
                        .foregroundStyle(.gray.opacity(0.25))
                }
            }
            .chartPlotStyle {
                $0.border(Color.gray)
            }
            .accessibilityChartDescriptor(self)
            
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(Color.tint1)
                    .scaleEffect(stateModel.scaleFactor, anchor: .center)
                if stateModel.avrHr > 0 {
                    Text("\(stateModel.avrHr) Average BMP")
                        .font(.caption1)
                }
                
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Accessibility
extension EcgView: AXChartDescriptorRepresentable {
    public func makeChartDescriptor() -> AXChartDescriptor {
        let min = stateModel.data.min() ?? 0.0
        let max = stateModel.data.max() ?? 0.0
        
        // Set the units when creating the axes
        // so users can scrub and pause to narrow on a data point
        let xAxis = AXNumericDataAxisDescriptor(
            title: "Time",
            range: Double(0)...Double(stateModel.data.count),
            gridlinePositions: []
        ) { value in "\(value)s" }
        
        
        let yAxis = AXNumericDataAxisDescriptor(
            title: "Millivolts",
            range: Double(min)...Double(max),
            gridlinePositions: []
        ) { value in "\(value) mV" }
        
        let series = AXDataSeriesDescriptor(
            name: "ECG data",
            isContinuous: true,
            dataPoints: stateModel.data.enumerated().map {
                .init(x: Double($0), y: $1)
            }
        )
        
        return AXChartDescriptor(
            title: "ElectroCardiogram (ECG)",
            summary: nil,
            xAxis: xAxis,
            yAxis: yAxis,
            additionalAxes: [],
            series: [series]
        )
    }
}

// MARK: - Preview
//struct HeartBeat_Previews: PreviewProvider {
//    static var previews: some View {
//        HeartBeat(vm: .init(data: HealthData.ecgSample, isOverview: true, frequency: 128))
//        HeartBeat(vm: .init(data: HealthData.ecgSample, isOverview: false, frequency: 128))
//    }
//}

