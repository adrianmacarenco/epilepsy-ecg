//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 22/05/2023.
//

import Foundation
import SwiftUI
import Combine
import Model
import StylePackage
import SwiftUINavigation
import Dependencies
import DBClient
import PersistenceClient

public class GenderSelectionViewModel: ObservableObject {
    enum Destination {
        case weightSelection(WeightSelectionViewModel)
    }
    @Published var route: Destination?
    @Published var selectedGender: String = ""
    @Dependency (\.dbClient) var dbClient
    @Dependency (\.persistenceClient) var persistenceClient
    
    var genders = ["Male", "Female"]
    let now = Date()
    
    var oldestPersonAlive: Date {
            let calendar = Calendar.current
            let currentDate = Date()
            let oldestDateComponents = DateComponents(year: calendar.component(.year, from: currentDate) - 10)
            return calendar.date(from: oldestDateComponents)!
        }
    
    var localUser: User
    
    public init(user: User) {
        self.localUser = user
    }
    
    var isNextButtonEnabled: Bool {
        !selectedGender.isEmpty
    }
    
    func nextButtonTapped() {
        guard genders.contains(selectedGender) else { return }
        localUser.gender = selectedGender
        route = .weightSelection(
            withDependencies(from: self) {
                .init(user: localUser)
            }
        )
    }
    
    func didTapGenderCell(_ index: Int) {
        guard index < genders.count else { return }
        selectedGender = genders[index]
    }

}

public struct GenderSelectionView: View {
    @ObservedObject var vm: GenderSelectionViewModel
    
    public init (
        vm: GenderSelectionViewModel
    ) {
        self.vm = vm
    }
    public var body: some View {
        VStack(spacing: 16) {
            Image.genderIcon
            Text("Gender-specific Factors")
                .font(.largeInput)
            Text("Please select your gender. This information helps us consider any gender-specific factors that may impact your heart health and epilepsy management.")
                .padding(.horizontal, 16)
                .font(.body1)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            ForEach(0 ..< vm.genders.count, id: \.self) { index in
                GenderCell(
                    title: vm.genders[index],
                    vm: .init(isSelected: vm.selectedGender == vm.genders[index])
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    vm.didTapGenderCell(index)
                }
            }
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
            case: /GenderSelectionViewModel.Destination.weightSelection
        ) { $weightSelectionVm in
            WeightSelectionView(vm: weightSelectionVm)
        }
    }
}


class GenderCellViewModel: ObservableObject {
    @Published var isSelected: Bool
    
    init(isSelected: Bool) {
        self.isSelected = isSelected
    }
}
struct GenderCell: View {
    let title: String
    @ObservedObject var vm: GenderCellViewModel
    
    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .font(.title1)
                    .foregroundColor(.black)
                Spacer()
                if vm.isSelected {
                    Image.checked
                } else {
                    Circle()
                        .stroke(Color.separator, lineWidth: 1)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.all, 16)
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
        .background(vm.isSelected ? Color.background2 : Color.clear)
        .cornerRadius(8)
        .overlay(
            vm.isSelected ? nil : RoundedRectangle(cornerRadius: 8).stroke(Color.separator, lineWidth: 1)
        )
    }
}
