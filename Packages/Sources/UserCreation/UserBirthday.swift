//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 22/05/2023.
//

import Foundation
import SwiftUI
import Combine
import StylePackage
import SwiftUINavigation

public class UserBirthdayViewModel: ObservableObject {
    enum Destination {
        case genderSelection(GenderSelectionViewModel)
    }
    @Published var route: Destination?
    @Published var birthdayDate: Date?
    let now = Date()
    
    var oldestPersonAlive: Date {
            let calendar = Calendar.current
            let currentDate = Date()
            let oldestDateComponents = DateComponents(year: calendar.component(.year, from: currentDate) - 10)
            return calendar.date(from: oldestDateComponents)!
        }
    
    public init() {}
    
    
    var isNextButtonEnabled: Bool {
        guard let birthdayDate else { return false }
        return birthdayDate < now
    }
    
    func nextButtonTapped() {
        route = .genderSelection(.init())
    }
    
    func setBirthday(_ date: Date) {
        self.birthdayDate = date
    }

}

public struct UserBirthdayView: View {
    @ObservedObject var vm: UserBirthdayViewModel
    
    public init (
        vm: UserBirthdayViewModel
    ) {
        self.vm = vm
    }
    public var body: some View {
        VStack(spacing: 16) {
            Text("Age Calculation")
                .font(.largeInput)
            Text("Please provide your date of birth. This information allows us to calculate your age, which is important for tailoring your heart monitoring and seizure management recommendations.")
                .padding(.horizontal, 16)
                .font(.body1)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            DatePicker(
                "Select your birthday",
                selection: Binding<Date>.init(
                    get: { vm.birthdayDate ?? Date() },
                    set: vm.setBirthday(_:)),
                in: vm.oldestPersonAlive ... vm.now,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .background(Color.white)
            .cornerRadius(13)
            .tint(.tint1)
            Spacer()
            Button("Next", action: vm.nextButtonTapped)
                .buttonStyle(MyButtonStyle.init(style: .primary, isEnabled: vm.isNextButtonEnabled))
                .padding(.bottom, 58)
                .disabled(!vm.isNextButtonEnabled)
        }
        .padding(.horizontal, 16)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
        .background(Color.background)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(
            unwrapping: self.$vm.route,
            case: /UserBirthdayViewModel.Destination.genderSelection
        ) { $genderSelectionVm in
            GenderSelectionView(vm: genderSelectionVm)
        }
    }
}

