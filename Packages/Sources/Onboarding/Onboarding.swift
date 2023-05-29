//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 22/05/2023.
//

import Foundation
import SwiftUI
import StylePackage


public class OnboardingViewModel: ObservableObject, Equatable {
    public static func == (lhs: OnboardingViewModel, rhs: OnboardingViewModel) -> Bool {
        lhs.onboardingSteps.count == rhs.onboardingSteps.count
    }
    

    enum OnboardingStep: Int, CaseIterable {
        case welcome
        case bluetoothPermission
        case scan
        case connect
        
        func title() -> String {
            switch self {
            case .welcome:
                return "Welcome to EpiHeartMonitor!"
            case .bluetoothPermission:
                return "Give bluetooth permission"
            case .scan:
                return "Scan available devices"
            case .connect:
                return "Connect to your device"
            }
        }
        
        func message() -> String {
            switch self {
                 
            case .welcome:
                return "Thank you for choosing our app! We're excited to have you on board."
            case .bluetoothPermission:
                return "Enable Bluetooth permission to access nearby devices."
            case .scan:
                return "Discover and view a list of nearby devices ready to connect."
            case .connect:
                return "Establish a secure connection with your preferred device."
            }
        }
        
        func icon() -> Image {
            switch self {
                 
            case .welcome:
                return .onboardingGettingStarted
            case .bluetoothPermission:
                return .onboardingPermission
            case .scan:
                return .onboardingSearch
            case .connect:
                return .onboardingConnect
            }
        }
    }
    
    @Published var currentIndex = 0
    let onboardingSteps = OnboardingStep.allCases
    var primaryButtonTitle: String {
        if currentIndex < onboardingSteps.count {
            let step = onboardingSteps[currentIndex]
            switch step {
            case .welcome:
                return "Start onboarding"
            case .connect:
                return "Finish"
            default: return "Next"
            }
        } else {
            fatalError("Should not be greater")
        }
    }
    
    var pageControllerOpacity: Double {
        currentIndex == 0 ? 0 : 1
    }
    
    var showSecondaryBotton: Bool {
        currentIndex == 0 ? true : false
    }
    
    public init() {}
    
    func primaryButtonTapped() {
        if currentIndex < onboardingSteps.count - 1 {
            withAnimation {
                currentIndex += 1
            }
        }
    }
    
    func secondaryButtonTapped() {
        
    }
    
    func nextStepDrag() {
        if currentIndex < onboardingSteps.count - 1 {
            withAnimation {
                currentIndex += 1
            }
        }
    }

    func prevStepDrag() {
        if currentIndex > 0 {
            withAnimation {
                currentIndex -= 1
            }
        }
    }
}

public struct OnboardingView: View {
    @ObservedObject var vm: OnboardingViewModel

    public init (
        vm: OnboardingViewModel
    ) {
        self.vm = vm
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            vm.onboardingSteps[vm.currentIndex].icon()
                .padding(.top, 32)
            
            Text(vm.onboardingSteps[vm.currentIndex].title())
                .font(.largeInput)
            
            Text(vm.onboardingSteps[vm.currentIndex].message())
                .font(.body1)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            Spacer()

            if vm.showSecondaryBotton {
                Button("No, not this time", action: vm.secondaryButtonTapped)
                    .buttonStyle(MyButtonStyle.init(style: .primary, isEnabled: false))
            }

            Button(vm.primaryButtonTitle, action: vm.primaryButtonTapped)
                .buttonStyle(MyButtonStyle.init(style: .primary))
            
            HStack {
                ForEach(0 ..< vm.onboardingSteps.count, id: \.self) { index in
                    Circle()
                        .fill(index == vm.currentIndex ? Color.tint1 : Color.gray)
                        .frame(width: 10, height: 10)
                        .padding(5)
                }
            }
            .opacity(vm.pageControllerOpacity)
            
        }
        .padding(.horizontal, 16)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
        .background(Color.background)
        .gesture(DragGesture(minimumDistance: 3.0, coordinateSpace: .local)
            .onEnded({ value in
                if (value.startLocation.x > value.location.x) {
                    vm.nextStepDrag()
                } else if (value.startLocation.x < value.location.x) {
                    vm.prevStepDrag()
                }
            })
        )
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Onboarding")

    }
}
