//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 27/05/2023.
//

import Foundation
import Combine
import SwiftUI
import DBClient
import Dependencies
import PersistenceClient
import Model
import UserCreation
import HomeTabbar
import SwiftUINavigation
import WidgetClient
import WidgetKit
import BackgroundTasks

public class AppViewModel: ObservableObject {
    public enum Destination {
        case userCreation(GettingStartedViewModel)
        case home(HomeTabbarViewModel)
    }
    @Published var route: Destination?
    @Dependency (\.dbClient) var dbClient
    @Dependency (\.persistenceClient) var persistenceClient
    @Dependency(\.widgetClient) var widgetClient
    @Dependency(\.bluetoothClient) var bluetoothClient
    let taskIdentifier = "dk.dtu.compute.Epilepsy-ECG.refresh"

    // MARK: - Public interface
    public init() {
        if let user = persistenceClient.user.load() {
            Task {
                do {
                    _ = try await dbClient.getUser(user.id)
                    await MainActor.run { [weak self] in
                        self?.presentHomeScreen()
                    }
                } catch {
                    print("Error fetching the user")
                    await MainActor.run { [weak self] in
                        self?.presentUserCretionFlow()
                    }
                }
            }
        } else {
            presentUserCretionFlow()
        }

        NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: .main) { [weak self] _ in
            self?.setDisconnectedStatus()
        }
        register()
    }
        
    func setDisconnectedStatus() {
        widgetClient.updateConnectionStatus(false)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetClient.kind)
    }
    
    func scenePhaseChanged(newValue: ScenePhase) {
        switch newValue {
        case .background where bluetoothClient.isDeviceConnected():
            scheduleAppRefresh()
            print("scheduled")
        default:
            break
        }
    }
    
    // MARK: - Private interface
    func userCreationFlowEnded() {
        if let user = persistenceClient.user.load() {
            Task {
                do {
                    _ = try await dbClient.getUser(user.id)
                    await MainActor.run { [weak self] in
                        self?.presentHomeScreen()
                    }
                } catch {
                    print("Error fetching the user")
                }
            }
        }
    }
    
    func onConfirmUserDeletion() {
        persistenceClient.user.save(nil)
        persistenceClient.deviceNameSerial.save(nil)
        persistenceClient.deviceConfigurations.save(nil)
        persistenceClient.ecgConfiguration.save(nil)
        persistenceClient.medications.save(nil)
        persistenceClient.medicationIntakes.save(nil)
        Task {
            try await dbClient.deleteCurrentDb()
            await MainActor.run { [weak self] in
                self?.presentUserCretionFlow()
            }
        }
    }
    
    func presentHomeScreen() {
        self.route = .home(
            withDependencies(from: self) {
                HomeTabbarViewModel(onConfirmProfileDeletion: { [weak self] in self?.onConfirmUserDeletion() })
            }
        )
    }
    
    func presentUserCretionFlow() {
        self.route = .userCreation(
            withDependencies(from: self) {
                GettingStartedViewModel(userCreationFlowEnded: { [weak self] in self?.userCreationFlowEnded() })
            }
        )
    }
    
    private func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            self.handleAppRefresh(task: task as! BGProcessingTask)
        }
    }
    
    private func scheduleAppRefresh() {
        let request = BGProcessingTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 5 * 60)
        request.requiresExternalPower = true
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
        NSLog("⭐️ Scheduled for app refresh")
        print("⭐️ Scheduled for app refresh")

    }
    
    private func handleAppRefresh(task: BGProcessingTask) {
        scheduleAppRefresh()
        let isDeviceConnected = bluetoothClient.isDeviceConnected()
        widgetClient.updateConnectionStatus(isDeviceConnected)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetClient.kind)
        task.setTaskCompleted(success: true)
        print("⭐️ handle app refresh")
        NSLog("⭐️ handle app refresh")
    }
    
}

public struct AppView: View {
    @ObservedObject var vm: AppViewModel
    @Environment(\.scenePhase) var scenePhase

    public init(
        vm: AppViewModel
    ) {
        self.vm = vm
    }
    
    public var body: some View {
        IfLet($vm.route) { $destination in
            Switch($destination) {
                CaseLet(/AppViewModel.Destination.userCreation) { $userCreationVm in
                    GettingStartedView(vm: userCreationVm)
                 }
                CaseLet(/AppViewModel.Destination.home) { $homeViewModel in
                    HomeTabbarView(vm: homeViewModel)
                        .onChange(of: scenePhase, perform: vm.scenePhaseChanged(newValue:))
                }
            }
        }
    }
}
