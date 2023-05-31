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

public class DiagnosisViewModel: ObservableObject {
    enum Destination {
        case medicationList(MedicationListViewModel)
    }
    @Published var route: Destination?
    @Published var diagnosis = ""
    @Dependency (\.dbClient) var dbClient
    @Dependency (\.persistenceClient) var persistenceClient
    
    var localUser: User
    var userCreationFlowEnded: () -> Void = unimplemented("DeviceInfoViewModel.onConfirmDeletion")

 // MARK: - Public interface
    
    public init(
        user: User,
        userCreationFlowEnded: @escaping() -> Void
    ) {
        self.localUser = user
        self.userCreationFlowEnded = userCreationFlowEnded
    }
    
    var isNextButtonEnabled: Bool {
        diagnosis.count > 2
    }
    
    // MARK: - Private interface

    @MainActor
    private func createUser() async throws {
        let savedUser = try await dbClient.createUser(localUser.id, localUser.fullName, localUser.birthday, localUser.gender, localUser.weight, localUser.height, localUser.diagnosis)
        persistenceClient.user.save(savedUser)
        route = .medicationList(
            withDependencies(from: self) {
                .init(
                    user: savedUser,
                    userCreationFlowEnded: self.userCreationFlowEnded
                )
            }
        )
    }
    
    // MARK: - Actions
    func nextButtonTapped() {
        guard diagnosis.count > 2 else { return }
        localUser.diagnosis = diagnosis

        Task {
            do {
                try await createUser()
            } catch {
                print("🫥 ERROR \(error) ")
            }
        }
    }
    
    func skipTapped() {
        Task {
            do {
                try await createUser()
            } catch {
                print("🫥 ERROR \(error) ")
            }
        }
    }
}

public struct DiagnosisView: View {
    @ObservedObject var vm: DiagnosisViewModel
    
    public init (
        vm: DiagnosisViewModel
    ) {
        self.vm = vm
    }
    public var body: some View {
        VStack(spacing: 16) {
            Text("Epilepsy Diagnosis Details")
                .font(.largeInput)
            Text("Understanding the type of epilepsy you've been diagnosed with helps us provide you with the most accurate and personalized monitoring plan. Please type your epilepsy diagnosis. If you're unsure about your diagnosis, you can consult with your physician or proceed with the 'Skip' option, and we'll do our best to support you.")
                .padding(.horizontal, 16)
                .font(.body1)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            TextField(
                "Diagnosis",
                text: $vm.diagnosis,
                prompt: Text("Type").foregroundColor(.gray)
            )
            .textFieldStyle(EcgTextFieldStyle())
            Spacer()
            Button("Next", action: vm.nextButtonTapped)
                .buttonStyle(MyButtonStyle.init(style: .primary, isEnabled: vm.isNextButtonEnabled))
                .disabled(!vm.isNextButtonEnabled)
                .padding(.bottom, 58)
        }
        .padding(.horizontal, 16)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
        .background(Color.background)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(
            unwrapping: self.$vm.route,
            case: /DiagnosisViewModel.Destination.medicationList
        ) { $medicationListVm in
            MedicationListView(vm: medicationListVm)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
            Button("Skip") {
                vm.skipTapped()
            }
          }
        }
        
    }
}
