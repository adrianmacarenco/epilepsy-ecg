//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 26/05/2023.
//

import Foundation
import Combine
import SwiftUI
import StylePackage
import Model
import Dependencies
import DBClient
import PersistenceClient
import SwiftUINavigation
import Localizations

public class IntakeHistoryViewModel: ObservableObject {
    enum Destination {
        case editIntake(TrackIntakeViewModel)
    }
    @Published var intakes: [MedicationIntake] = []
    @Published var route: Destination?
    
    @Dependency (\.dbClient) var dbClient
    @Dependency (\.persistenceClient) var persistenceClient
    // MARK: - Public Interface
    
    public init() {}
    
    func task() async {
        do {
            let intakeHistory = try await dbClient.fetchIntakes()
            await MainActor.run {
                intakes = intakeHistory
            }
        } catch {
            print("🫥 ERROR \(error.localizedDescription)")
        }
    }
    // MARK: - Private Interface
    
    
    // MARK: - Actions
    
    func dailyIntakeCellTapped(index: Int) {
        guard index < intakes.count else { return }
        
        route = .editIntake(
            withDependencies(from: self, operation: {
                .init(
                    type: .edit(intakes[index]),
                    intakeEditted: { [weak self] in
                        Task { @MainActor [weak self] in
                            self?.route = nil
                            
                        }
                    }
                )
            })
        )
    }
}

public struct IntakeHistoryView: View {
    @ObservedObject var vm: IntakeHistoryViewModel
    @EnvironmentObject var localizations: ObservableLocalizations

    public init(
        vm: IntakeHistoryViewModel
    ) {
        self.vm = vm
    }
    
    public var body: some View {
        ScrollView {
            VStack {
                ForEach(0 ..< vm.intakes.count, id: \.self) { index in
                    IntakeCellView(intake: vm.intakes[index], isDailyPreview: false)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            vm.dailyIntakeCellTapped(index: index)
                        }
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 16)
            .task { await vm.task() }
        }
        .background(Color.background)
        .navigationTitle(localizations.trackIntakeSection.intakeHistoryTitle)
        .navigationDestination(
            unwrapping: self.$vm.route,
            case: /IntakeHistoryViewModel.Destination.editIntake
        ) { $editIntakeVm in
            TrackIntakeView(vm: editIntakeVm)
        }
    }
}
