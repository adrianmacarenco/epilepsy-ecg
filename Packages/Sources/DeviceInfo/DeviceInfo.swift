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

    // MARK: - Public Interface
    
    public init(
        connectedDevice: DeviceWrapper,
        onConfirmDeletion: @escaping () -> Void
    ) {
        self.connectedDevice = connectedDevice
        self.onConfirmDeletion = onConfirmDeletion
    }
    
    func forgetDeviceTapped() {
        route = .alert(.delete)
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
    public enum Component: String, CaseIterable, Equatable {
        case productName = "Product name"
        case serialNumber = "Serial number"
        case software = "Software version"
        case hardware = "Hardware version"
        case mode = "Mode"
        
        public func description(info: MovesenseDeviceInfo?) -> String {
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
                    return "Full power off(1)"
                case 5:
                    return "Application(5)"
                case 12:
                    return "Firmaware update(12)"
                default:
                    return "Unknown"
                }
            }
        }
    }
}

public struct DeviceInfoView: View {
    @ObservedObject var vm: DeviceInfoViewModel
    
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
                            title: vm.components[index].rawValue,
                            description: vm.components[index].description(info: vm.connectedDevice.movesenseDevice.deviceInfo)
                        )
                    }
                    Spacer()
                    Button("Forget device", action: vm.forgetDeviceTapped)
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
        .navigationTitle("Device information")
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
  static let delete = AlertState(
    title: TextState("Forget device"),
    message: TextState("Are you sure you want to forget this device?"),
    buttons: [
      .destructive(TextState("Yes"), action: .send(.confirmDeletion)),
      .cancel(TextState("No"))
    ]
  )
}
