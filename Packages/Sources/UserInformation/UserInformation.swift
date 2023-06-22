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
import XCTestDynamicOverlay
import Localizations

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
    @Dependency (\.localizations) var localizations
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
                        },
                        userCreationFlowEnded: unimplemented("UserInformationViewModel.onConfirmDeletion")
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
                        },
                        userCreationFlowEnded: unimplemented("UserInformationViewModel.onConfirmDeletion")
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
                        },
                        userCreationFlowEnded: unimplemented("UserInformationViewModel.onConfirmDeletion")
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
                        },
                        userCreationFlowEnded: unimplemented("UserInformationViewModel.onConfirmDeletion")
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
                        },
                        userCreationFlowEnded: unimplemented("UserInformationViewModel.onConfirmDeletion")
                    )
                })
            )
        case .currentMedications:
            route = .medicationList(
                withDependencies(from: self, operation: {
                    MedicationListViewModel(
                        user: self.user,
                        type: .edit(medications),
                        userCreationFlowEnded: unimplemented("UserInformationViewModel.onConfirmDeletion")
                    )
                })
            )
        }
    }
}

extension UserInformationViewModel {
    public enum Component: CaseIterable, Equatable {
        case fullName
        case birthday
        case gender
        case weight
        case height
        case currentMedications
        
        public func description(user: User, userInfoLocalizations: Localizations.UserInformationSection) -> String? {
            switch self {
            case .fullName:
                return user.fullName != nil ? userInfoLocalizations.editNameDescription : nil
            case .birthday:
                return user.birthday != nil ? userInfoLocalizations.editBirthdayDescription : nil
            case .gender:
                return user.gender != nil ? userInfoLocalizations.editGenderDescription : nil
            case .weight:
                return user.weight != nil ? userInfoLocalizations.editWeightDescription : nil
            case .height:
                return user.height != nil ? userInfoLocalizations.editHeightDescription : nil
            case .currentMedications:
                return nil
            }
        }
        
        public func title(user: User, userInfoLocalizations: Localizations.UserInformationSection) -> String {
            switch self {
            case .fullName:
                return user.fullName ?? userInfoLocalizations.editNameDescription
            case .birthday:
                return user.birthday != nil ? Date.dayMonthYear.string(from: user.birthday!) : userInfoLocalizations.editBirthdayDescription
            case .gender:
                return user.gender ?? userInfoLocalizations.editGenderDescription
            case .weight:
                return user.weight != nil ? String(format: "%.0f", user.weight!) : userInfoLocalizations.editWeightDescription
            case .height:
                return user.height != nil ? String(format: "%.0f", user.height!) : userInfoLocalizations.editHeightDescription
            case .currentMedications:
                return userInfoLocalizations.editMedicationListDescription
            }
        }
    }
}

public struct UserInformationView: View {
    @ObservedObject var vm: UserInformationViewModel
    @EnvironmentObject var localizations: ObservableLocalizations

    public init(
        vm: UserInformationViewModel
    ) {
        self.vm = vm
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(0 ..< vm.components.count, id: \.self) { index in
                        ProfileCellView(
                            description: vm.components[index].description(user: vm.user, userInfoLocalizations: localizations.userInformationSection),
                            title: vm.components[index].title(user: vm.user, userInfoLocalizations: localizations.userInformationSection)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            vm.componentTapped(index: index)
                        }
                    }

                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                .frame(height: geometry.size.height)
                .padding(.horizontal, 16)
                .task { await vm.task() }
                .navigationDestination(
                    unwrapping: self.$vm.route,
                    case: /UserInformationViewModel.Destination.fullName
                ) { $personalIdenityVm in
                    PersonalIdentityView(vm: personalIdenityVm)
                        .navigationTitle(localizations.userInformationSection.editNameTitle)
                }
                .navigationDestination(
                    unwrapping: self.$vm.route,
                    case: /UserInformationViewModel.Destination.birthday
                ) { $birthdayVm in
                    UserBirthdayView(vm: birthdayVm)
                        .navigationTitle(localizations.userInformationSection.editBirthdayTitle)
                }
                .navigationDestination(
                    unwrapping: self.$vm.route,
                    case: /UserInformationViewModel.Destination.gender
                ) { $genderVm in
                    GenderSelectionView(vm: genderVm)
                        .navigationTitle(localizations.userInformationSection.editGenderTitle)
                }
                .navigationDestination(
                    unwrapping: self.$vm.route,
                    case: /UserInformationViewModel.Destination.weight
                ) { $weightVm in
                    WeightSelectionView(vm: weightVm)
                        .navigationTitle(localizations.userInformationSection.editWeightTitle)
                }
                .navigationDestination(
                    unwrapping: self.$vm.route,
                    case: /UserInformationViewModel.Destination.height
                ) { $heightVm in
                    HeightSelectionView(vm: heightVm)
                        .navigationTitle(localizations.userInformationSection.editHeightTitle)
                }
                .navigationDestination(
                    unwrapping: self.$vm.route,
                    case: /UserInformationViewModel.Destination.medicationList
                ) { $medicaitonsVm in
                    MedicationListView(vm: medicaitonsVm)
                        .navigationTitle(localizations.userInformationSection.editMedicationListTitle)
                }
            }
        }
        .background(Color.background)
        .navigationTitle(localizations.userInformationSection.userInformationTitle)
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
