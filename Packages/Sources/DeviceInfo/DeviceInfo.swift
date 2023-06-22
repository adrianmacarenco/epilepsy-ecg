//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 29/05/2023.
//

import Foundation
import SwiftUI
import Combine
import Model
import StylePackage
import MovesenseApi
import XCTestDynamicOverlay
import SwiftUINavigation
import SwiftUINavigation
import Localizations
import Dependencies
import Shared

public class DeviceInfoViewModel: ObservableObject {

    public enum Destination {
        case alert(AlertState<AlertAction>)
    }
    
    public enum AlertAction {
      case confirmDeletion
    }
    
    @Published var components = Component.allCases
    @Published var route: Destination?
    let connectedDevice: DeviceWrapper
    var onConfirmDeletion: () -> Void = unimplemented("DeviceInfoViewModel.onConfirmDeletion")
    @Dependency (\.localizations) var localizations

    // MARK: - Public Interface
    
    public init(
        connectedDevice: DeviceWrapper,
        onConfirmDeletion: @escaping () -> Void
    ) {
        self.connectedDevice = connectedDevice
        self.onConfirmDeletion = onConfirmDeletion
    }
    
    func forgetDeviceTapped() {
        route = .alert(.delete(
            title: localizations.deviceInfo.forgetDeviceAlertTitle,
            message: localizations.deviceInfo.forgetDeviceAlertMessage,
            yesBtnTitle: localizations.defaultSection.yes.capitalizedFirstLetter(),
            notBtnTitle: localizations.defaultSection.no.capitalizedFirstLetter()
        ))
    }
    
    func alertButtonTapped(_ action: AlertAction) {
      switch action {
      case .confirmDeletion:
        self.onConfirmDeletion()
      }
    }
}
extension DeviceInfoViewModel: Equatable {
    public static func == (lhs: DeviceInfoViewModel, rhs: DeviceInfoViewModel) -> Bool {
        lhs.connectedDevice == rhs.connectedDevice
    }
}
extension DeviceInfoViewModel {
    public enum Component: CaseIterable, Equatable {
        case productName
        case serialNumber
        case software
        case hardware
        case mode
        
        public func title(deviceInfoLocalizations: Localizations.DeviceInfo) -> String {
            switch self {
            case .productName:
                return deviceInfoLocalizations.productName
            case .serialNumber:
                return deviceInfoLocalizations.serialNumber
            case .software:
                return deviceInfoLocalizations.software
            case .hardware:
                return deviceInfoLocalizations.hardware
            case .mode:
                return deviceInfoLocalizations.mode
            }
        }
        
        public func description(info: MovesenseDeviceInfo?, deviceInfoLocalizations: Localizations.DeviceInfo) -> String {
            guard let info else { return "Unknown" }
            switch self {
            case .productName:
                return info.name
            case .serialNumber:
                return info.serialNumber
            case .software:
                return info.swVersion
            case .hardware:
                return info.hwVersion
            case .mode:
                switch info.mode {
                case 1:
                    return deviceInfoLocalizations.firstMode
                case 5:
                    return deviceInfoLocalizations.secondMode
                case 12:
                    return deviceInfoLocalizations.thirdMode
                default:
                    return "Unknown"
                }
            }
        }
    }
}

public struct DeviceInfoView: View {
    @ObservedObject var vm: DeviceInfoViewModel
    @EnvironmentObject var localizations: ObservableLocalizations

    public init(
        vm: DeviceInfoViewModel
    ) {
        self.vm = vm
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(0 ..< vm.components.count, id: \.self) { index in
                        DeviceInfoCell(
                            title: vm.components[index].title(deviceInfoLocalizations: localizations.deviceInfo),
                            description: vm.components[index].description(info: vm.connectedDevice.movesenseDevice.deviceInfo, deviceInfoLocalizations: localizations.deviceInfo)
                        )
                    }
                    Spacer()
                    Button(localizations.deviceInfo.forgetDeviceBtnTitle, action: vm.forgetDeviceTapped)
                        .buttonStyle(MyButtonStyle.init(style: .delete))
                        .padding(.bottom, 24)
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                .frame(height: geometry.size.height)
                .padding(.horizontal, 16)
            }
            .background(Color.background)
            .alert(
              unwrapping: self.$vm.route,
              case: /DeviceInfoViewModel.Destination.alert
            ) { action in
              self.vm.alertButtonTapped(action)
            }
        }
        .navigationTitle(localizations.deviceInfo.deviceInfoScreenTitle)
    }
}




public struct DeviceInfoCell: View {
    let title: String
    let description: String
    
    public init(title: String, description: String) {
        self.description = description
        self.title = title
    }
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .font(.caption4)
                    .foregroundColor(.gray)
                
                Text(description)
                    .font(.title1)
                    .foregroundColor(.black)
            }
            .padding(10)
            Spacer()
        }
        .background(Color.white)
        .cornerRadius(8)
    }
}


extension AlertState where Action == DeviceInfoViewModel.AlertAction {
    static func delete(title: String, message: String, yesBtnTitle: String, notBtnTitle: String) -> AlertState {
        AlertState(
            title: TextState(title),
            message: TextState(message),
            buttons: [
                .destructive(TextState(yesBtnTitle), action: .send(.confirmDeletion)),
                .cancel(TextState(notBtnTitle))
            ]
        )
    }
}
