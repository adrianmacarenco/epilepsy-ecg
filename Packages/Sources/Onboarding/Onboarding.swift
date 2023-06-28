//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 22/05/2023.
//

import Foundation
import Combine
import SwiftUI
import StylePackage
import Dependencies
import Localizations
import XCTestDynamicOverlay
import Shared


public class OnboardingViewModel: ObservableObject, Equatable {
    public static func == (lhs: OnboardingViewModel, rhs: OnboardingViewModel) -> Bool {
        lhs.onboardingSteps.count == rhs.onboardingSteps.count
    }
    

    enum OnboardingStep: Int, CaseIterable {
        case welcome
        case bluetoothPermission
        case scan
        case connect
        
        func title(onboardingSection: Localizations.OnboardingSection) -> String {
            switch self {
            case .welcome:
                return onboardingSection.welcomeTitle
            case .bluetoothPermission:
                return onboardingSection.bluetoothPermissionTitle
            case .scan:
                return onboardingSection.scanTitle
            case .connect:
                return onboardingSection.connectTitle
            }
        }
        
        func message(onboardingSection: Localizations.OnboardingSection) ->  String {
            switch self {
                 
            case .welcome:
                return onboardingSection.welcomeMessage
            case .bluetoothPermission:
                return onboardingSection.bluetoothPermissionMessage
            case .scan:
                return onboardingSection.scanMessage
            case .connect:
                return onboardingSection.connectMessage
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
    @Dependency(\.localizations) var localizations

    let onboardingSteps = OnboardingStep.allCases
    var endOnboardingFlowAction: () -> Void = unimplemented("DeviceInfoViewModel.onConfirmDeletion")

    var primaryButtonTitle: String {
        if currentIndex < onboardingSteps.count {
            let step = onboardingSteps[currentIndex]
            switch step {
            case .welcome:
                return localizations.defaultSection.continueKey.capitalizedFirstLetter()
            case .connect:
                return localizations.defaultSection.finish.capitalizedFirstLetter()
            default:
                return localizations.defaultSection.next.capitalizedFirstLetter()
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
    
    public init(
        endOnboardingFlowAction: @escaping() -> Void
    ) {
        self.endOnboardingFlowAction = endOnboardingFlowAction
    }
    
    func primaryButtonTapped() {
        if currentIndex < onboardingSteps.count - 1 {
            withAnimation {
                currentIndex += 1
            }
        } else if currentIndex == onboardingSteps.count - 1 {
            endOnboardingFlowAction()
        }
    }
    
    func secondaryButtonTapped() {
        endOnboardingFlowAction()
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
    @EnvironmentObject var localizations: ObservableLocalizations

    public init (
        vm: OnboardingViewModel
    ) {
        self.vm = vm
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            vm.onboardingSteps[vm.currentIndex].icon()
                .padding(.top, 32)
            
            Text(vm.onboardingSteps[vm.currentIndex].title(onboardingSection: localizations.onboardingSection))
                .font(.largeInput)
            
            Text(vm.onboardingSteps[vm.currentIndex].message(onboardingSection: localizations.onboardingSection))
                .font(.body1)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            Spacer()

            if vm.showSecondaryBotton {
                Button(localizations.onboardingSection.notNowBtnTitle, action: vm.secondaryButtonTapped)
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
        .navigationTitle(localizations.onboardingSection.screenTitle)

    }
}
