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
    public static let movesenseDevice = Image(decorative: "iconDevice", bundle: .myModule)
    public static let checked = Image(decorative: "iconChecked", bundle: .myModule)
    public static let iconProfileTab = Image(decorative: "iconProfileTab", bundle: .myModule)
    public static let iconHomeTab = Image(decorative: "iconHomeTab", bundle: .myModule)
    public static let pillTab = Image(systemName: "pill")
    public static let pickerIndicator = Image(systemName: "chevron.down")
    
    //UserCreation
    public static let gettingStarted = Image(decorative: "gettingStartedIcon", bundle: .myModule)
    public static let genderIcon = Image(decorative: "genderIcon", bundle: .myModule)
    
    // Onboarding
    public static let onboardingConnect = Image(decorative: "onboardingConnect", bundle: .myModule)
    public static let onboardingPermission = Image(decorative: "onboardingPermission", bundle: .myModule)
    public static let onboardingSearch = Image(decorative: "onboardingSearch", bundle: .myModule)
    public static let onboardingGettingStarted = Image(decorative: "onboardingGettingStarted", bundle: .myModule)

}
