//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 29/05/2023.
//

import Foundation
import SwiftUI
import StylePackage
import Model
import DBClient
import Shared
import PersistenceClient
import UserCreation
import Dependencies
import SwiftUINavigation

public class UserInformationViewModel: ObservableObject {
    enum Destination {
        case fullName(PersonalIdentityViewModel)
        case birthday(UserBirthdayViewModel)
        case gender(GenderSelectionViewModel)
        case weight(WeightSelectionViewModel)
        case height(HeightSelectionViewModel)
        case medicationList(MedicationListViewModel)
    }
    @Published var components = Component.allCases
    @Published var user: User
    @Published var route: Destination?
    @Dependency (\.dbClient) var dbClient
    @Dependency (\.persistenceClient) var persistenceClient
    var medications: [Medication] = []
    public init(
        user: User
    ) {
        self.user = user
    }
    
    func task() async {
        do {
            medications = try await dbClient.fetchMedications()

        } catch {
            print("🫥 ERROR: \(error.localizedDescription)")
        }
    }
    
    func componentTapped(index: Int) {
        guard index < components.count else { return }
        switch components[index] {
        case .fullName:
            route = .fullName(
                withDependencies(from: self, operation: {
                    PersonalIdentityViewModel(
                        user: self.user,
                        type: .edit(user),
                        userUpdated: { [weak self] updatedUser in
                            Task { @MainActor [weak self] in
                                self?.route = nil
                                self?.user = updatedUser
                            }
                        }
                    )
                })
            )
        case .birthday:
            route = .birthday(
                withDependencies(from: self, operation: {
                    UserBirthdayViewModel(
                        user: self.user,
                        type: .edit(user),
                        userUpdated: { [weak self] updatedUser in
                            Task { @MainActor [weak self] in
                                self?.route = nil
                                self?.user = updatedUser
                            }
                        }
                    )
                })
            )
        case .gender:
            route = .gender(
                withDependencies(from: self, operation: {
                    GenderSelectionViewModel(
                        user: self.user,
                        type: .edit(user),
                        userUpdated: { [weak self] updatedUser in
                            Task { @MainActor [weak self] in
                                self?.route = nil
                                self?.user = updatedUser
                            }
                        }
                    )
                })
            )
        case .weight:
            route = .weight(
                withDependencies(from: self, operation: {
                    WeightSelectionViewModel(
                        user: self.user,
                        type: .edit(user),
                        userUpdated: { [weak self] updatedUser in
                            Task { @MainActor [weak self] in
                                self?.route = nil
                                self?.user = updatedUser
                            }
                        }
                    )
                })
            )
        case .height:
            route = .height(
                withDependencies(from: self, operation: {
                    HeightSelectionViewModel(
                        user: self.user,
                        type: .edit(user),
                        userUpdated: { [weak self] updatedUser in
                            Task { @MainActor [weak self] in
                                self?.route = nil
                                self?.user = updatedUser
                            }
                        }
                    )
                })
            )
        case .currentMedications:
            route = .medicationList(
                withDependencies(from: self, operation: {
                    MedicationListViewModel(
                        user: self.user,
                        type: .edit(medications)
                    )
                })
            )
        }
    }
}

extension UserInformationViewModel {
    public enum Component: String, CaseIterable, Equatable {
        case fullName = "Full name"
        case birthday = "Birthday"
        case gender = "Gender"
        case weight = "Weight"
        case height = "Height"
        case currentMedications = "Current medications"
        
        public func description() -> String? {
            switch self {
            case .currentMedications:
                return nil
            default:
                return self.rawValue
            }
        }
        
        public func title(user: User) -> String {
            switch self {
            case .fullName:
                return user.fullName
            case .birthday:
                return Date.dayMonthYear.string(from: user.birthday)
            case .gender:
                return user.gender
            case .weight:
                return String(format: "%.0f", user.weight)
            case .height:
                return String(format: "%.0f", user.height)
            case .currentMedications:
                return self.rawValue
            }
        }
    }
}

public struct UserInformationView: View {
    @ObservedObject var vm: UserInformationViewModel
    
    public init(
        vm: UserInformationViewModel
    ) {
        self.vm = vm
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(0 ..< vm.components.count, id: \.self) { index in
                    ProfileCellView(
                        description: vm.components[index].description(),
                        title: vm.components[index].title(user: vm.user)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        vm.componentTapped(index: index)
                    }
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 16)
            .task { await vm.task() }
            .navigationDestination(
                unwrapping: self.$vm.route,
                case: /UserInformationViewModel.Destination.fullName
            ) { $personalIdenityVm in
                PersonalIdentityView(vm: personalIdenityVm)
                    .navigationTitle("Edit name")
            }
            .navigationDestination(
                unwrapping: self.$vm.route,
                case: /UserInformationViewModel.Destination.birthday
            ) { $birthdayVm in
                UserBirthdayView(vm: birthdayVm)
                    .navigationTitle("Edit birthday")
            }
            .navigationDestination(
                unwrapping: self.$vm.route,
                case: /UserInformationViewModel.Destination.gender
            ) { $genderVm in
                GenderSelectionView(vm: genderVm)
                    .navigationTitle("Edit gender")
            }
            .navigationDestination(
                unwrapping: self.$vm.route,
                case: /UserInformationViewModel.Destination.weight
            ) { $weightVm in
                WeightSelectionView(vm: weightVm)
                    .navigationTitle("Edit weight")
            }
            .navigationDestination(
                unwrapping: self.$vm.route,
                case: /UserInformationViewModel.Destination.height
            ) { $heightVm in
                HeightSelectionView(vm: heightVm)
                    .navigationTitle("Edit height")
            }
            .navigationDestination(
                unwrapping: self.$vm.route,
                case: /UserInformationViewModel.Destination.medicationList
            ) { $medicaitonsVm in
                MedicationListView(vm: medicaitonsVm)
                    .navigationTitle("Edit medications list")
            }
        }
        .background(Color.background)
        .navigationTitle("User information")
    }
}


public struct ProfileCellView: View {
    let description: String?
    let title: String
    
    public init(description: String? = nil, title: String) {
        self.description = description
        self.title = title
    }
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading) {
                if let description {
                    Text(description)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        .font(.caption4)
                        .foregroundColor(.gray)
                }
                
                Text(title)
                    .font(.title1)
                    .foregroundColor(.black)
            }
            .padding(description == nil ? 16 : 10)
            Spacer()
            
            Image.openIndicator
                .padding(.trailing, 16)
        }
        .background(Color.white)
        .cornerRadius(8)
    }
}
