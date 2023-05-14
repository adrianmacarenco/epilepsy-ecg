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
import Dependencies
import PersistenceClient
import BluetoothClient
import IdentifiedCollections
import Model
import Charts
import SwiftUICharts
import ECG
import ECG_Settings
import Combine

public class DashboardViewModel: ObservableObject {
    enum Destination: Equatable {
        case addDevice(AddDeviceViewModel)
        case ecgSettings(EcgSettingsViewModel)
    }
    
    @Published var route: Destination?
    @Published var previousDevices: IdentifiedArrayOf<DeviceNameSerial> = []
    @Published var discoveredDevices: IdentifiedArrayOf<DeviceWrapper> = []
    @Published var connectedDevices: IdentifiedArrayOf<DeviceWrapper> = []
    @Published var ecgViewModel: EcgViewModel = .init()
    
    @Dependency(\.persistenceClient) var persistenceClient
    @Dependency(\.bluetoothClient) var bluetoothClient
    @Dependency (\.continuousClock) var clock
    var cancellable: AnyCancellable?
    
    let frequency = 128
    let previewInterval = 4
    var index = 0
    var previewIntervalSamplesNr: Int {
        frequency * previewInterval
    }

    var mockedData = ecgDataValues.flatMap { $0 }
    
    public init() {}
    
    func onAppear() {

        if let ecgConfig = persistenceClient.ecgViewConfiguration.load() {
            ecgViewModel.configuration = ecgConfig
        }
        if let savedDeviceNameSerial = persistenceClient.deviceNameSerial.load() {
            //Display the previous device here
            previousDevices.append(savedDeviceNameSerial)
            bluetoothClient.scanDevices()
        }
//
//        let sampleCountPerPacket = self.frequency / self.secondRate
//
//        Task {
//            for await _ in clock.timer(interval: .milliseconds(frequency))  {
//                Task { @MainActor [weak self] in
//                    guard let self = self else { return }
//                    try await self.clock.sleep(for: .milliseconds(sampleCountPerPacket))
//                    if self.index + sampleCountPerPacket >= self.samples.count {
//                        self.index = 0
//                    }
//                    let subset = Array(self.mockedData[index ..< self.index + sampleCountPerPacket])
//                    for (subsetIndex, value) in zip(subset.indices, subset) {
//                        self.samples[index + subsetIndex] = Double(value)
//                    }
//
//                    self.index += sampleCountPerPacket
//                }
//            }
//        }
        
    }
    
    @MainActor
    func task() async {
        Task {
            for await device in bluetoothClient.discoveredDevicesStream() {
                discoveredDevices.append(device)
            }
        }
        
        for await ecgData in bluetoothClient.ecgPacketsStream() {
//            self.ecgData.append(contentsOf: ecgData.samples)
            ecgData.samples.forEach { sample in
                Task { @MainActor in
//                    try await clock.sleep(for: .milliseconds(5))
                    self.ecgViewModel.data[index] =  Double(sample)
                    index += 1
                    if index ==  previewIntervalSamplesNr {
                        index = 0
                        ecgViewModel.data = Array(repeating: 0.0, count: 512)
                        
                    }
                }

            }
        }
    }
    
    func addDeviceButtonTapped() {
        let addDeviceViewModel = withDependencies(from: self) {
            AddDeviceViewModel()
        }
        route = .addDevice(addDeviceViewModel)
    }
    
    func cancelAddDeviceTapped() {
        route = nil
    }
    
    func connectButtonTapped(deviceNameSerial: DeviceNameSerial) {
        guard let deviceWrapper = discoveredDevices.first(where: { $0.movesenseDevice.serialNumber == deviceNameSerial.serial }) else {
            return
        }
        
        Task { @MainActor in
            let connectedDevice = try await bluetoothClient.connectToDevice(deviceWrapper)
            connectedDevices.append(connectedDevice)
            bluetoothClient.stopScanningDevices()
            try await clock.sleep(for: .seconds(3))
            bluetoothClient.subscribeToEcg(connectedDevice, 128)
            // Start ECG to show the preview
        }
    }
    
    func disconnectButtonTapped(deviceNameSerial: DeviceNameSerial) {
        guard let deviceWrapper = discoveredDevices.first(where: { $0.movesenseDevice.serialNumber == deviceNameSerial.serial }) else { return }
        
        Task { @MainActor in
            
            let disconnectedDevice = try await bluetoothClient.disconnectDevice(deviceWrapper)
            connectedDevices.remove(disconnectedDevice)
            
        }
    }
    
    func ecgViewTapped() {
        route = .ecgSettings( withDependencies(from: self) { .init(
            ecgModel: ecgViewModel,
            computeTime: {_ in return 0.0},
            colorSelected: { _ in })
        })
    }
    
    func isConnectable(deviceSerial: String) -> Bool {
        discoveredDevices.contains{ $0.movesenseDevice.serialNumber == deviceSerial } && !connectedDevices.contains{ $0.movesenseDevice.serialNumber == deviceSerial }
    }
    
    func isDisconnectable(deviceSerial: String) -> Bool {
        connectedDevices.contains{ $0.movesenseDevice.serialNumber == deviceSerial }
    }
    
    func computeTime(for index: Int) -> Double {
        let elapsedTime = Double(index) / Double(frequency)
            // Calculate the time within the current 4-second interval
        let timeValue = elapsedTime.truncatingRemainder(dividingBy: Double(ecgViewModel.configuration.timeInterval))
                
        return timeValue
    }
    
    func colorSelected(_ newColor: Color) {
        self.ecgViewModel.configuration.chartColor = newColor
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
        NavigationStack {
            VStack {
                ForEach(vm.previousDevices) { deviceSerialName in
                    DeviceCell(
                        deviceSerialName: deviceSerialName,
                        connectButtonTapped: { vm.connectButtonTapped(deviceNameSerial: deviceSerialName)},
                        disconnectButtonTapped: { vm.disconnectButtonTapped(deviceNameSerial: deviceSerialName)},
                        vm: .init(
                            isConnectEnabled: vm.isConnectable(deviceSerial: deviceSerialName.serial),
                            isDisconnectEnabled: vm.isDisconnectable(deviceSerial: deviceSerialName.serial
                                                                    )))
                    .padding(.horizontal, 16)
                }
                VStack {
                    EcgView(
                        model: $vm.ecgViewModel,
                        computeTime: vm.computeTime
                    )
                    .background(Color.white)
                    .padding(.all, 16)
                    .onTapGesture(perform: vm.ecgViewTapped)
                    
                }
                .background(Color.white)
                .cornerRadius(20)
                .padding(.horizontal, 16)
                Spacer()
                Button("Add my device", action: vm.addDeviceButtonTapped)
                    .buttonStyle(MyButtonStyle.init(style: .primary))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 58)
                Divider()
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
            .background(Color.background)
            .onAppear(perform: vm.onAppear)
            .task { await vm.task() }
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
            .navigationDestination(
                unwrapping: self.$vm.route,
                case: /DashboardViewModel.Destination.ecgSettings
            ) { $ecgSettingsVm in
              EcgSettingsView(vm: ecgSettingsVm)
            }
        }
    }
}

class DeviceCellViewModel: ObservableObject {
    @Published var isConnectEnabled: Bool
    @Published var isDisconnectEnabled: Bool
    
    init(isConnectEnabled: Bool, isDisconnectEnabled: Bool) {
        self.isConnectEnabled = isConnectEnabled
        self.isDisconnectEnabled = isDisconnectEnabled
    }
}

struct DeviceCell: View {
    let deviceSerialName: DeviceNameSerial
    let connectButtonTapped: () -> ()
    let disconnectButtonTapped: () -> ()
    @ObservedObject var vm: DeviceCellViewModel

    var body: some View {
        VStack {
            Text(deviceSerialName.localName)
                .foregroundColor(.black)
                .font(.headline2)
                .padding(.all, 16)
            HStack {
                Button("Connect", action: connectButtonTapped)
                .padding(.all, 16)
                .buttonStyle(MyButtonStyle.init(style: .primary, isEnabled: vm.isConnectEnabled))

                Spacer()
                Button("Disconnect", action: disconnectButtonTapped)
                .padding(.all, 16)
                .buttonStyle(MyButtonStyle.init(style: .primary, isEnabled: vm.isDisconnectEnabled))
            }
        }
        .background(Color.white)
        .cornerRadius(20)
    }
}


var ecgDataValues: [[Int]] = [[-2929, -2914, -2899, -2882, -2858, -2829, -2793, -2743, -2690, -2634, -2584, -2530, -2471, -2411, -2359, -2306], [-2252, -2197, -2145, -2093, -2048, -2005, -1961, -1910, -1860, -1817, -1777, -1733, -1685, -1643, -1605, -1567], [-1528, -1488, -1442, -1396, -1348, -1309, -1277, -1246, -1210, -1169, -1132, -1100, -1065, -1022, -981, -949], [-923, -900, -874, -840, -807, -777, -750, -726, -697, -668, -643, -622, -597, -568, -545, -524], [-501, -478, -456, -429, -409, -390, -374, -349, -331, -313, -289, -267, -254, -234, -204, -167],[-136, -125, -128, -145, -169, -182, -163, -125, -100, -91, -84, -72, -54, -42, -25, -13],[-4, 16, 33, 44, 41, 126, 610, 1314, 1175, -411, -2383, -3048, -2024, -531, 233, 314],[346, 456, 490, 502, 520, 522, 520, 527, 526, 524, 525, 528, 530, 532, 527, 528],[533, 532, 533, 537, 539, 547, 552, 558, 562, 564, 561, 554, 540, 511, 478, 445],[414, 391, 372, 355, 328, 291, 255, 208, 162, 118, 90, 73, 64, 55, 51, 49],[50, 52, 58, 61, 62, 61, 57, 55, 60, 63, 60, 53, 45, 45, 47, 41],[34, 28, 28, 27, 31, 35, 44, 48, 44, 37, 43, 49, 52, 53, 52, 53],[60, 62, 68, 67, 72, 78, 76, 70, 67, 75, 85, 81, 79, 77, 81, 90],[96, 99, 96, 91, 92, 93, 99, 101, 98, 98, 100, 109, 118, 115, 106, 103],[111, 117, 124, 125, 121, 118, 124, 128, 134, 148, 159, 169, 165, 153, 130, 94],[66, 69, 95, 114, 108, 101, 104, 114, 118, 123, 124, 123, 130, 138, 139, 134],[266, 812, 1392, 923, -857, -2630, -2889, -1654, -275, 293, 322, 371, 467, 485, 489, 499],[485, 484, 493, 486, 476, 466, 469, 479, 476, 466, 451, 445, 448, 450, 450, 450],[453, 467, 478, 483, 480, 470, 458, 441, 415, 375, 338, 316, 302, 289, 263, 222],[187, 137, 81, 23, -25, -47, -64, -78, -91, -87, -85, -86, -90, -95, -96, -94],[-96, -99, -97, -96, -100, -104, -107, -107, -107, -109, -113, -113, -109, -109, -112, -113],[-114, -107, -98, -98, -96, -95, -86, -83, -81, -85, -84, -76, -72, -72, -72, -71],[-70, -72, -69, -67, -64, -61, -57, -55, -51, -50, -51, -50, -47, -41, -38, -37],[-34, -34, -32, -30, -29, -22, -16, -18, -21, -22, -17, -14, -15, -3, 18, 37],[39, 39, 38, 18, -29, -68, -61, -30, -8, -13, -21, -22, -14, -5, 6, 13],[17, 24, 24, 23, 22, 206, 826, 1370, 736, -1157, -2836, -2888, -1560, -262, 195, 200],[276, 368, 375, 387, 394, 382, 384, 383, 379, 373, 370, 373, 373, 368, 362, 359],[358, 354, 350, 352, 354, 360, 364, 367, 368, 369, 368, 348, 315, 274, 242, 223],[216, 202, 182, 159, 130, 91, 41, -14, -60, -93, -118, -141, -153, -157, -161, -165],[-171, -165, -161, -159, -161, -166, -169, -174, -172, -170, -175, -184, -187, -185, -185, -187],[-190, -189, -190, -188, -183, -178, -178, -175, -171, -168, -165, -159, -157, -153, -154, -148],[-143, -139, -135, -132, -133, -137, -139, -135, -130, -127, -128, -125, -119, -119, -122, -120],[-114, -108, -98, -94, -93, -93, -91, -87, -82, -73, -71, -66, -63, -61, -55, -47],[-45, -43, -43, -40, -38, -36, -41, -34, -16, 3, 7, 3, -13, -41, -80, -104],
[-87, -50, -35, -41, -55, -56, -47, -35, -28, -30, -25, -13, -4, 0, -7, 161],
[750, 1265, 628, -1256, -2944, -3010, -1669, -330, 165, 179, 250, 343, 356, 363, 368, 362],
[360, 359, 355, 350, 347, 343, 345, 348, 347, 340, 332, 327, 332, 336, 337, 336],
[341, 347, 350, 349, 341, 320, 296, 262, 231, 205, 191, 179, 166, 152, 130, 89],
[35, -25, -68, -101, -128, -148, -161, -168, -173, -172, -164, -166, -169, -176, -175, -174],
[-173, -173, -166, -158, -162, -170, -180, -182, -183, -181, -178, -174, -170, -175, -176, -175],
[-173, -171, -168, -159, -152, -154, -156, -153, -146, -145, -146, -144, -140, -136, -134, -131],
[-124, -118, -118, -123, -120, -118, -112, -104, -100, -98, -94, -89, -86, -87, -87, -83],
[-81, -85, -81, -74, -69, -66, -71, -69, -59, -56, -56, -57, -54, -50, -50, -51],
[-48, -42, -39, -42, -40, -38, -32, -15, 4, 14, 12, 4, -12, -44, -76, -86],
[-65, -39, -38, -46, -53, -50, -40, -34, -32, -27, -17, -4, -2, -8, 14, 330],
[1017, 1259, 133, -1870, -3087, -2567, -1094, -49, 184, 183, 281, 340, 334, 349, 355, 354],
[352, 345, 342, 341, 339, 334, 333, 333, 334, 328, 326, 323, 321, 319, 318, 320],
[325, 326, 323, 318, 316, 304, 274, 235, 195, 171, 161, 156, 149, 131, 102, 61],
[14, -35, -82, -116, -142, -155, -168, -179, -180, -175, -172, -176, -179, -174, -169, -170],
[-169, -174, -174, -175, -175, -180, -183, -188, -185, -186, -185, -185, -187, -189, -184, -179],
[-169, -168, -171, -174, -168, -154, -146, -143, -137, -130, -119, -118, -121, -122, -118, -118],
[-117, -119, -115, -116, -117, -116, -114, -114, -117, -111, -104, -100, -100, -102, -101, -99],
[-95, -88, -86, -85, -83, -79, -72, -71, -71, -76, -80, -79, -72, -70, -67, -67],
[-63, -65, -68, -69, -62, -55, -52, -56, -51, -31, -10, 1, -1, -14, -35, -76],
[-106, -105, -73, -52, -55, -62, -65, -59, -53, -47, -36, -33, -25, -24, -26, -30],
[69, 561, 1212, 975, -645, -2537, -3083, -2024, -601, 89, 157, 197, 304, 326, 331, 348],
[345, 341, 338, 336, 337, 331, 324, 318, 317, 323, 321, 319, 310, 302, 303, 306],
[314, 321, 327, 327, 325, 322, 317, 302, 275, 239, 203, 179, 165, 162, 146, 116],
[77, 30, -23, -77, -124, -157, -180, -190, -202, -206, -212, -212, -208, -199, -197, -193],
[-189, -184, -179, -180, -178, -176, -177, -180, -181, -186, -194, -205, -208, -204, -200, -199],
[-200, -203, -203, -200, -195, -192, -195, -200, -199, -195, -189, -187, -184, -181, -176, -170],
[-169, -170, -170, -164, -159, -157, -157, -157, -151, -147, -145, -142, -136, -130, -126, -127],
[-127, -126, -119, -114, -109, -110, -109, -105, -100, -100, -92, -87, -82, -80, -88, -85],
[-83, -79, -75, -70, -69, -70, -64, -39, -21, -13, -16, -27, -54, -94, -117, -105],
[-73, -60, -66, -71, -71, -65, -57, -53, -49, -43, -31, -21, -24, -38, 100, 655],
[1245, 785, -1005, -2808, -3090, -1850, -450, 135, 166, 215, 312, 327, 336, 347, 339, 334],
[334, 331, 329, 323, 326, 330, 325, 316, 303, 299, 299, 299, 298, 295, 295, 303],
[309, 313, 309, 301, 290, 269, 240, 203, 170, 148, 142, 135, 123, 93, 53, 9],
[-36, -79, -122, -158, -182, -193, -196, -202, -204, -201, -196, -189, -189, -191, -192, -193],
[-193, -191, -188, -185, -189, -193, -198, -196, -193, -198, -202, -204, -200, -195, -192, -184],
[-181, -182, -182, -185, -177, -167, -162, -161, -165, -164, -156, -148, -146, -148, -143, -133],
[-131, -133, -137, -133, -120, -118, -121, -123, -119, -114, -112, -109, -104, -99, -103, -100],
[-97, -91, -86, -81, -76, -79, -77, -78, -75, -73, -68, -66, -68, -69, -66, -67],
[-62, -61, -61, -57, -53, -49, -50, -54, -53, -47, -42, -33, -12, 6, 12, 8],
[0, -26, -62, -93, -85, -53, -37, -43, -51, -50, -42, -40, -38, -35, -23, -11],
[-13, -15, -14, 120, 652, 1239, 824, -915, -2715, -3042, -1854, -468, 127, 165, 223, 324],
[338, 344, 358, 356, 348, 344, 342, 340, 334, 330, 323, 321, 317, 312, 309, 304],
[305, 305, 308, 313, 321, 326, 326, 319, 316, 303, 281, 252, 218, 193, 172, 158],
[151, 135, 114, 80, 31, -24, -78, -120, -154, -174, -186, -195, -199, -206, -209, -205],
[-197, -191, -196, -197, -191, -187, -188, -193, -197, -192, -192, -193, -201, -201, -200, -199],
[-202, -202, -201, -194, -190, -185, -181, -181, -182, -179, -172, -165, -163, -159, -156, -154],
[-150, -150, -147, -145, -140, -135, -130, -128, -128, -127, -123, -119, -118, -114, -112, -110],
[-111, -108, -102, -99, -102, -102, -100, -93, -96, -96, -95, -89, -84, -79, -73, -71],
[-73, -74, -74, -70, -66, -65, -65, -64, -52, -35, -18, -11, -5, -16, -55, -106],
[-123, -93, -58, -56, -72, -77, -67, -58, -54, -50, -45, -37, -25, -19, -26, -32],
[157, 752, 1232, 535, -1372, -3017, -3027, -1665, -336, 149, 168, 238, 331, 341, 348, 363],
[359, 355, 346, 341, 342, 333, 324, 317, 319, 315, 310, 307, 307, 308, 305, 302],
[302, 311, 316, 312, 298, 285, 275, 263, 235, 201, 177, 164, 163, 158, 142, 120],
[89, 45, -10, -64, -112, -147, -167, -179, -189, -196, -193, -191, -187, -183, -177, -174],
[-170, -176, -178, -179, -174, -171, -174, -173, -175, -184, -191, -192, -190, -185, -187, -185],
[-181, -173, -171, -174, -179, -178, -171, -163, -163, -165, -165, -154, -140, -132, -132, -138],
[-142, -134, -127, -124, -128, -129, -120, -116, -113, -116, -118, -115, -114, -112, -103, -98],
[-95, -95, -94, -90, -87, -87, -86, -81, -77, -77, -79, -76, -72, -71, -69, -58],
[-38, -23, -19, -15, -24, -50, -92, -114, -103, -74, -60, -62, -72, -73, -67, -56],
[-51, -49, -47, -35, -32, -28, -32, 56, 542, 1226, 1043, -560, -2504, -3132, -2105, -656],
[63, 132, 169, 277, 302, 306, 327, 323, 319, 314, 305, 299, 295, 291, 290, 288],
[285, 280, 283, 279, 281, 276, 273, 272, 275, 273, 270, 261, 248, 231, 208, 179],
[147, 120, 109, 116, 125, 126, 100, 64, 19, -28, -80, -126, -161, -180, -188, -191],
[-193, -192, -193, -194, -189, -188, -188, -192, -192, -190, -188, -192, -193, -196, -196, -202],
[-203, -203, -201, -201, -202, -206, -204, -202, -197, -195, -196, -198, -193, -189, -186, -186],
[-187, -179, -170, -170, -176, -178, -172, -164, -157, -147, -143, -145, -150, -148, -140, -133],
[-133, -133, -129, -124, -122, -116, -111, -109, -110, -108, -103, -101, -94, -92, -89, -85],
[-84, -84, -83, -79, -79, -81, -83, -81, -75, -71, -71, -70, -67, -67, -67, -68],
[-68, -66, -60, -59, -55, -56, -52, -50, -52, -56, -44, -22, 1, 8, -3, -26],
[-63, -103, -120, -105, -77, -68, -73, -79, -75, -65, -64, -61, -62, -55, -46, -41],
[-48, -48, 141, 741, 1225, 541, -1363, -3012, -3035, -1677, -347, 138, 153, 227, 320, 334],
[340, 348, 346, 342, 335, 328, 332, 334, 333, 328, 324, 317, 309, 303, 302, 304],
[310, 318, 321, 323, 321, 322, 323, 312, 297, 277, 252, 222, 188, 163, 151, 147],
[142, 115, 76, 35, -8, -53, -99, -137, -156, -168, -178, -189, -191, -186, -176, -168],
[-173, -178, -178, -175, -167, -165, -166, -171, -174, -178, -180, -184, -186, -192, -190, -188],
[-185, -182, -183, -190, -193, -191, -180, -170, -169, -172, -176, -170, -163, -159, -158, -156],
[-150, -148, -148, -146, -142, -136, -128, -131, -131, -135, -130, -125, -117, -111, -112, -118],
[-115, -110, -111, -115, -117, -114, -106, -104, -105, -102, -100, -97, -96, -90, -87, -84],
[-79, -73, -72, -76, -75, -70, -68, -66, -69, -65, -61, -64, -64, -62, -59, -61],
[-64, -63, -63, -62, -48, -34, -23, -22, -19, -21, -42, -85, -117, -114, -85, -69],
[-75, -82, -78, -66, -61, -57, -54, -46, -37, -34, -41, -48, 57, 573, 1227, 945],
[-733, -2635, -3143, -2037, -596, 82, 140, 186, 293, 313, 316, 332, 335, 332, 327, 316],
[314, 312, 309, 305, 302, 299, 293, 288, 283, 284, 287, 287, 286, 286, 287, 290],
[281, 273, 258, 240, 212, 175, 138, 106, 90, 88, 84, 71, 45, 5, -39, -85],
[-125, -158, -182, -190, -198, -202, -203, -207, -210, -206, -206, -205, -208, -208, -209, -201],
[-193, -187, -188, -195, -200, -204, -204, -202, -196, -198, -204, -205, -197, -192, -193, -194],
[-192, -189, -186, -183, -177, -168, -165, -166, -161, -151, -146, -144, -143, -144, -139, -134],
[-133, -126, -124, -128, -128, -122, -116, -109, -105, -105, -108, -104, -102, -98, -99, -99],
[-98, -92, -87, -86, -89, -86, -80, -77, -77, -77, -77, -73, -70, -67, -64, -63],
[-64, -66, -65, -62, -58, -57, -55, -52, -46, -46, -49, -43, -26, -8, 0, 4],
[-4, -27, -69, -102, -101, -71, -50, -52, -60, -58, -50, -46, -44, -48, -44, -33],
[-21, -19, -32, 5, 341, 976, 1075, -173, -2160, -3248, -2614, -1103, -59, 182, 185, 281],
[344, 349, 362, 371, 365, 359, 351, 346, 344, 338, 330, 322, 313, 310, 307, 307],
[307, 299, 293, 286, 288, 296, 301, 295, 285, 276, 267, 240, 203, 161, 129, 109],
[93, 88, 84, 66, 41, 8, -30, -69, -104, -130, -147, -158, -166, -174, -175, -174],
[-171, -164, -159, -157, -156, -158, -166, -165, -159, -151, -149, -157, -164, -164, -161, -167],
[-176, -177, -171, -166, -170, -176, -175, -167, -158, -154, -155, -154, -151, -145, -142, -142],
[-144, -146, -144, -142, -139, -131, -128, -124, -120, -115, -114, -115, -116, -110, -103, -103],
[-111, -113, -107, -101, -97, -101, -103, -103, -101, -98, -98, -88, -88, -92, -95, -93],
[-89, -82, -83, -83, -84, -83, -80, -77, -78, -77, -72, -67, -62, -44, -27, -19],
[-23, -28, -47, -76, -118, -126, -106, -85, -74, -77, -81, -82, -82, -76, -69, -57],
[-44, -36, -34, -41, 46, 517, 1206, 1075, -462, -2401, -3089, -2139, -704, 42, 127, 162],
[278, 311, 308, 316, 311, 312, 313, 314, 314, 318, 314, 309, 301, 296, 290, 288],
[289, 293, 284, 288, 296, 305, 308, 309, 313, 317, 311, 297, 268, 235, 198, 167],
[143, 129, 119, 102, 66, 15, -37, -79, -115, -150, -176, -199, -208, -211, -212, -211],
[-210, -212, -213, -213, -208, -203, -200, -204, -208, -210, -206, -211, -217, -222, -220, -218],
[-224, -226, -221, -215, -210, -204, -201, -202, -201, -202, -202, -198, -192, -186, -179, -184],
[-188, -186, -176, -167, -164, -164, -165, -159, -150, -146, -140, -138, -138, -133, -133, -132],
[-127, -120, -118, -117, -114, -107, -106, -107, -105, -97, -93, -93, -94, -95, -90, -84],
[-76, -73, -73, -75, -72, -72, -65, -50, -29, -17, -15, -26, -45, -84, -115, -117],
[-90, -71, -69, -76, -79, -71, -61, -56, -51, -44, -37, -35, -36, -47, 55, 550],
[1191, 916, -762, -2704, -3263, -2161, -661, 82, 165, 202, 301, 328, 334, 358, 364, 358],
[348, 339, 335, 332, 324, 325, 320, 314, 306, 308, 313, 316, 314, 310, 307, 309],
[314, 319, 317, 309, 297, 281, 253, 225, 187, 149, 126, 108, 102, 88, 65, 28],
[-17, -61, -98, -129, -155, -176, -186, -187, -188, -188, -189, -190, -187, -182, -183, -183],
[-181, -172, -166, -164, -169, -174, -177, -172, -167, -168, -177, -179, -175, -174, -179, -178],
[-172, -166, -167, -165, -161, -156, -151, -152, -155, -157, -153, -141, -133, -136, -143, -142],
[-133, -126, -123, -122, -122, -120, -116, -111, -107, -98, -93, -98, -108, -102, -89, -78],
[-84, -91, -92, -85, -74, -68, -67, -69, -69, -69, -69, -65, -56, -53, -41, -20],
[-7, -5, -12, -30, -64, -102, -108, -85, -54, -49, -54, -57, -58, -58, -54, -50],
[-46, -39, -31, -27, -26, 34, 472, 1200, 1227, -188, -2181, -3064, -2248, -805, 16, 136],
[166, 280, 314, 309, 324, 324, 325, 325, 315, 308, 302, 296, 298, 296, 294, 288],
[282, 277, 279, 278, 281, 286, 293, 296, 292, 294, 292, 286, 265, 234, 198, 167],
[140, 127, 118, 103, 76, 45, 8, -34, -86, -141, -179, -199, -207, -217, -227, -230],
[-227, -225, -222, -222, -219, -213, -217, -216, -214, -211, -211, -216, -227, -230, -233, -229],
[-227, -225, -223, -226, -230, -228, -223, -214, -211, -214, -213, -210, -202, -197, -197, -189],
[-181, -177, -181, -178, -171, -166, -158, -156, -152, -146, -141, -134, -132, -133, -131, -127],
[-123, -121, -121, -119, -115, -112, -110, -109, -108, -105, -104, -99, -99, -96, -92, -84],
[-82, -76, -56, -35, -23, -23, -34, -56, -94, -127, -123, -97, -77, -79, -87, -87],
[-80, -71, -62, -55, -52, -41, -38, -38, -46, 80, 613, 1215, 814, -955, -2849, -3262],
[-2061, -577, 113, 177, 219, 317, 340, 344, 357, 355, 350, 346, 343, 337, 333, 324],
[324, 327, 324, 320, 316, 313, 312, 308, 311, 309, 311, 315, 312, 303, 290, 272],
[253, 222, 182, 138, 107, 92, 90, 80, 66, 43, 5, -33, -71, -105, -139, -168]]

