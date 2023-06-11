//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 10/06/2023.
//

import Foundation
import Dependencies

public struct WidgetClient {
    static let suiteName = "group.Epilepsy-ECG.shared"
    static let isConnectedKey = "isDeviceConnected"
    static let deviceBatteryPercentageKey = "deviceBatteryPercentage"
    static public let kind = "EpiHeartMonitorWidgets"
    
    public var updateConnectionStatus: (_ isConnect: Bool) -> Void
    public var updateBatteryPercentage: (_ newValue: Int) -> Void
    public var fetchConnectionStatus: () -> Bool?
    public var fetchBatteryPercentage: () -> Int?
    
    init(
        updateConnectionStatus: @escaping (_: Bool) -> Void,
        updateBatteryPercentage: @escaping (_: Int) -> Void,
        fetchConnectionStatus: @escaping () -> Bool?,
        fetchBatteryPercentage: @escaping () -> Int?
    ) {
        self.updateConnectionStatus = updateConnectionStatus
        self.updateBatteryPercentage = updateBatteryPercentage
        self.fetchConnectionStatus = fetchConnectionStatus
        self.fetchBatteryPercentage = fetchBatteryPercentage
    }
}

extension WidgetClient: DependencyKey {
    public static var liveValue: WidgetClient {
        let userDefaultsSuite = UserDefaults(suiteName: suiteName)!
        return .init(
            updateConnectionStatus: { userDefaultsSuite.set($0, forKey: isConnectedKey) },
            updateBatteryPercentage: { userDefaultsSuite.set($0, forKey: deviceBatteryPercentageKey) },
            fetchConnectionStatus: { userDefaultsSuite.value(forKey: isConnectedKey) as? Bool },
            fetchBatteryPercentage: { userDefaultsSuite.value(forKey: deviceBatteryPercentageKey) as? Int }
        )
    }
}

public extension DependencyValues {
    var widgetClient: WidgetClient {
        get { self[WidgetClient.self] }
        set { self[WidgetClient.self] = newValue }
    }
}
