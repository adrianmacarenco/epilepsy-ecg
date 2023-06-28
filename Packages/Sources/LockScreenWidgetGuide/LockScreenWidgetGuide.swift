//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 28/06/2023.
//

import Foundation
import Combine
import SwiftUI
import StylePackage
import Dependencies
import Localizations
import XCTestDynamicOverlay
import Shared

public class LockScreenWidgetGuideViewModel: ObservableObject, Equatable {
    public static func == (lhs: LockScreenWidgetGuideViewModel, rhs: LockScreenWidgetGuideViewModel) -> Bool {
        return lhs.guideSteps.count == rhs.guideSteps.count
    }
    
    enum GuideStep: Int, CaseIterable {
        case gettingStarted
        case lockScreen
        case customize
        case addWidget
        
        func title(widgetSection: Localizations.LockScreenWidgetGuideSection) -> String {
            switch self {
            case .gettingStarted:
                return widgetSection.lockScreenWidgetTitle
            case .lockScreen:
                return widgetSection.lockScreenModeTitle
            case .customize:
                return widgetSection.customizeLockScreenTitle
            case .addWidget:
                return widgetSection.addWidgetTitle
            }
        }
        
        func message(widgetSection: Localizations.LockScreenWidgetGuideSection) -> String {
            switch self {
            case .gettingStarted:
                return widgetSection.lockScreenWidgetMessage
            case .lockScreen:
                return widgetSection.lockScreenModeMessage
            case .customize:
                return widgetSection.customizeLockScreenMessage
            case .addWidget:
                return widgetSection.addWidgetMessage
            }
        }
        
        func icon() -> Image {
            switch self {
            case .gettingStarted:
                return .widgetGuideGettingStarted
            case .lockScreen:
                return .lockScreenMode
            case .customize:
                return .customizeLockScreen
            case .addWidget:
                return .addWidget
            }
        }
    }
    @Published var currentIndex = 0
    @Dependency(\.localizations) var localizations

    let guideSteps = GuideStep.allCases
    var endGuideFlowAction: () -> Void = unimplemented("DeviceInfoViewModel.onConfirmDeletion")

    
    var primaryButtonTitle: String {
        if currentIndex < guideSteps.count {
            let step = guideSteps[currentIndex]
            switch step {
            case .gettingStarted:
                return localizations.defaultSection.continueKey.capitalizedFirstLetter()
            case .addWidget:
                return localizations.defaultSection.finish.capitalizedFirstLetter()
            default: return localizations.defaultSection.next.capitalizedFirstLetter()
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
        endGuideFlowAction: @escaping() -> Void
    ) {
        self.endGuideFlowAction = endGuideFlowAction
    }
    func primaryButtonTapped() {
        if currentIndex < guideSteps.count - 1 {
            withAnimation {
                currentIndex += 1
            }
        } else if currentIndex == guideSteps.count - 1 {
            endGuideFlowAction()
        }
    }
    
    func secondaryButtonTapped() {
        endGuideFlowAction()
    }
    
    func nextStepDrag() {
        if currentIndex < guideSteps.count - 1 {
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

public struct LockScreenWidgetGuideView: View {
    @ObservedObject var vm: LockScreenWidgetGuideViewModel
    @EnvironmentObject var localizations: ObservableLocalizations

    public init (
        vm: LockScreenWidgetGuideViewModel
    ) {
        self.vm = vm
    }
    public var body: some View {
        VStack(spacing: 16) {
            vm.guideSteps[vm.currentIndex].icon()
                .padding(.top, 32)
            
            Text(vm.guideSteps[vm.currentIndex].title(widgetSection: localizations.lockScreenWidgetGuideSection))
                .font(.largeInput)
            
            Text(vm.guideSteps[vm.currentIndex].message(widgetSection: localizations.lockScreenWidgetGuideSection))
                .font(.body1)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            Spacer()

            if vm.showSecondaryBotton {
                Button(localizations.lockScreenWidgetGuideSection.notNowBtnTitle, action: vm.secondaryButtonTapped)
                    .buttonStyle(MyButtonStyle.init(style: .primary, isEnabled: false))
            }

            Button(vm.primaryButtonTitle, action: vm.primaryButtonTapped)
                .buttonStyle(MyButtonStyle.init(style: .primary))
            
            HStack {
                ForEach(0 ..< vm.guideSteps.count, id: \.self) { index in
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
        .navigationTitle(localizations.lockScreenWidgetGuideSection.screenTitle)

    }
}


