//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 01/05/2023.
//

import Foundation
import SwiftUI
import StylePackage
import AddDevice
import SwiftUINavigation

public class DashboardViewModel: ObservableObject {
    enum Destination: Equatable {
        case addDevice(AddDeviceViewModel)
    }
    
    @Published var route: Destination?
    
    public init() {
    }
    
    func addDeviceButtonTapped() {
        route = .addDevice(.init())
    }
    
    func cancelAddDeviceTapped() {
        route = nil
    }
}

public struct DashboardView: View {
    @ObservedObject var vm: DashboardViewModel
    public init(
        vm: DashboardViewModel
    ) {
        self.vm = vm
    }
    
    public var body: some View {
        VStack {
            Text("Dashboard view")
            Spacer()
            Button("Add my device", action: vm.addDeviceButtonTapped)
                .buttonStyle(MyButtonStyle.init(style: .primary))
                .padding(.horizontal, 16)
                .padding(.bottom, 58)
            Divider()
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
        .background(Color.background)
        .sheet(
            unwrapping: $vm.route,
            case: /DashboardViewModel.Destination.addDevice
        ) { $scanDevicesVm in
            NavigationStack {
                AddDeviceView(viewModel: scanDevicesVm)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarBackground(.white, for: .navigationBar)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(action: vm.cancelAddDeviceTapped) {
                                Text("Cancel")
                            }
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("Add device")
                                .font(.title1)
                                .foregroundColor(.black)
                        }
                    }
            }
            
        }
    }
}


