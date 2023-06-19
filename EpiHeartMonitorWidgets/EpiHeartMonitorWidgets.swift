//
//  EpiHeartMonitorWidgets.swift
//  EpiHeartMonitorWidgets
//
//  Created by Adrian Macarenco on 09/06/2023.
//

import WidgetKit
import SwiftUI
import Intents
import StylePackage
import WidgetClient
import Dependencies

struct Provider: IntentTimelineProvider {
    @Dependency(\.widgetClient) var widgetClient
    
    func placeholder(in context: Context) -> EpiHeartMonitorWidgetsEntryViewModel {
        EpiHeartMonitorWidgetsEntryViewModel(isConnected: false, batteryPercentage: -1)
    }
    
    func getSnapshot(for configuration: EpiHeartMonitorStatusIntent, in context: Context, completion: @escaping (EpiHeartMonitorWidgetsEntryViewModel) -> ()) {
        guard let isConnected = widgetClient.fetchConnectionStatus(),
              let batteryPercentage = widgetClient.fetchBatteryPercentage() else {
                  let vm = EpiHeartMonitorWidgetsEntryViewModel(isConnected: false, batteryPercentage: -1)
                  completion(vm)
                  return
              }
        
        let vm = EpiHeartMonitorWidgetsEntryViewModel(isConnected: isConnected, batteryPercentage: batteryPercentage)
        
        completion(vm)
        
    }
    
    func getTimeline(for configuration: EpiHeartMonitorStatusIntent, in context: Context, completion: @escaping (Timeline<EpiHeartMonitorWidgetsEntryViewModel>) -> ()) {
        guard
            let isConnected = widgetClient.fetchConnectionStatus(),
            let batteryPercentage = widgetClient.fetchBatteryPercentage() else {
            let vm = EpiHeartMonitorWidgetsEntryViewModel(isConnected: false, batteryPercentage: -1)
            completion(.init(entries: [vm], policy: .atEnd))
            return
        }
        
        
        let vm = EpiHeartMonitorWidgetsEntryViewModel(isConnected: isConnected, batteryPercentage: batteryPercentage)
        
        let timeline = Timeline(entries: [vm], policy: .atEnd)
        completion(timeline)
    }
}

struct EpiHeartMonitorWidgetsEntryViewModel {
    var isConnected: Bool
    var batteryPercentage: Int
    
    var batteryIcon: Image {
        switch batteryPercentage {
        case 76...100:
            return Image.batteryFullIcon
        case 51...75:
            return Image.batterySecondFullIcon
        case 26...50:
            return Image.batteryHalfIcon
        case 11...25:
            return Image.batteryQuarterIcon
        case 0...10:
            return Image.batteryLowIcon
        default:
            return Image.batteryLowIcon
        }
    }
}

extension EpiHeartMonitorWidgetsEntryViewModel: TimelineEntry {
    var date: Date {
        Date()
    }
}

struct EpiHeartMonitorWidgetsEntryView : View {
    let vm: EpiHeartMonitorWidgetsEntryViewModel
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        switch widgetFamily {
        case .accessoryRectangular:
            ZStack {
                AccessoryWidgetBackground()
                    .cornerRadius(8)
                VStack(spacing: 0) {
                    HStack {
                        Text("Movesense")
                            .font(.headline3)
                            .widgetAccentable()
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    HStack {
                        Image(systemName: vm.isConnected ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                        Text( vm.isConnected ? "Connected" : "Disconnected")
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    if vm.isConnected {
                        HStack {
                            vm.batteryIcon
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                            Text("\(vm.batteryPercentage) %")
                        }
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    }
                    
                }
                .padding(.horizontal, 6)
                .privacySensitive()
                .widgetAccentable()
            }
        default:
            Text("Not yet implemented")
        }
    }
}

struct EpiHeartMonitorWidgets: Widget {
    let kind: String = "EpiHeartMonitorWidgets"
    
    var body: some WidgetConfiguration {
        registerFonts()
        return IntentConfiguration(
            kind: kind,
            intent: EpiHeartMonitorStatusIntent.self,
            provider: Provider()) { entry in
                EpiHeartMonitorWidgetsEntryView(vm: entry)
            }
            .configurationDisplayName("EpiHeartMonitor Widget")
            .description("EpiHeartMonitor widget displays device connection status and its battery level")
            .supportedFamilies([
                .accessoryRectangular
            ])
        
    }
}

struct EpiHeartMonitorWidgets_Previews: PreviewProvider {
    static var previews: some View {
        EpiHeartMonitorWidgetsEntryView(vm: .init(isConnected: false, batteryPercentage: 10))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
