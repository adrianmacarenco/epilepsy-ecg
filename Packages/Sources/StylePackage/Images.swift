//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 01/05/2023.
//

import Foundation
import SwiftUI

class ImageBundle {}
extension Image {
    public static let movesenseDevice = Image(decorative: "deviceIcon", bundle: .myModule)
    public static let checkedIcon = Image(decorative: "checkedIcon", bundle: .myModule)
    public static let profileTabIcon = Image(decorative: "profileTabIcon", bundle: .myModule)
    public static let homeTabIcon = Image(decorative: "homeTabIcon", bundle: .myModule)
    public static let tackIntakeTabIcon = Image(decorative: "tackIntakeTabIcon", bundle: .myModule)
    
    // Default
    public static let plusIcon = Image(systemName: "plus")
    public static let pillIcon = Image(systemName: "pill.fill")
    public static let calendarIcon = Image(systemName: "calendar")
    public static let pillTab = Image(systemName: "pill")
    public static let pickerIndicator = Image(systemName: "chevron.down")
    public static let pillsIcon = Image(systemName: "pills.fill")
    public static let openIndicator = Image(systemName: "chevron.right")
    public static let clockIcon = Image(systemName: "clock")
    
    // Dashboard
    public static let addFirstDeviceIcon = Image(decorative: "addFirstDeviceIcon", bundle: .myModule)
    public static let batteryLowIcon = Image(decorative: "batteryLowIcon", bundle: .myModule)
    public static let batteryHalfIcon = Image(decorative: "batteryHalfIcon", bundle: .myModule)
    public static let batteryFullIcon = Image(decorative: "batteryFullIcon", bundle: .myModule)
    public static let batteryQuarterIcon = Image(decorative: "batteryQuarterIcon", bundle: .myModule)
    public static let batterySecondFullIcon = Image(decorative: "batterySecondFullIcon", bundle: .myModule)



    //UserCreation
    public static let gettingStarted = Image(decorative: "gettingStartedIcon", bundle: .myModule)
    public static let genderIcon = Image(decorative: "genderIcon", bundle: .myModule)


    // Onboarding
    public static let onboardingConnect = Image(decorative: "onboardingConnect", bundle: .myModule)
    public static let onboardingPermission = Image(decorative: "onboardingPermission", bundle: .myModule)
    public static let onboardingSearch = Image(decorative: "onboardingSearch", bundle: .myModule)
    public static let onboardingGettingStarted = Image(decorative: "onboardingGettingStarted", bundle: .myModule)

}
