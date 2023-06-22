//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 13/05/2023.
//

import Foundation


internal func loadTranslationsFromJSON(_ filename: String, in bundle: Bundle) -> Localizations {
    let path = bundle.path(forResource: filename, ofType: "json")!

    let data = try! String(contentsOfFile: path).data(using: .utf8)!

    let result = try! JSONDecoder().decode(Localizations.self, from: data)
    return result
}


public final class Localizations: Codable {
    public let defaultSection: DefaultSection
    public let dashboardSection: DashboardSection
    public let deviceInfo: DeviceInfo
    public let ecgSettings: EcgSettings
    public let accessibilitySection: AccessibilitySection
    public let trackIntakeSection: TrackIntakeSection
    public let profileSection: ProfileSection
    public let userInformationSection: UserInformationSection
    public let homeTabbarSection: HomeTabbarSection
    public let addMedicationSection: AddMedicationSection
    public let userCreationSection: UserCreationSection
    
    public final class DefaultSection: Codable {
        public let save: String
        public let cancel: String
        public let close: String
        public let connect: String
        public let disconnect: String
        public let seeMore: String
        public let yes: String
        public let no: String
        public let add: String
        public let update: String
        public let type: String
        public let next: String
        public let skip: String
        public let start: String
        public let finish: String
        public let interval: String
        public let second: String
        public let color: String
        public let frequency: String
        public let select: String
        public let edit: String
    }
    
    public final class DeviceInfo: Codable {
        public let productName: String
        public let serialNumber: String
        public let software: String
        public let hardware: String
        public let mode: String
        public let firstMode: String
        public let secondMode: String
        public let thirdMode: String
        public let forgetDeviceBtnTitle: String
        public let deviceInfoScreenTitle: String
        public let forgetDeviceAlertTitle: String
        public let forgetDeviceAlertMessage: String
    }
    
    public final class DashboardSection: Codable {
        public let getStartedTitle: String
        public let getStartedMessage: String
        public let ecgPlaceholderTitle: String
        public let ecgPlaceholderMessage: String
        public let ecgPreviewTitle: String
        public let dashboardTitle: String
        public let addMyDevice: String
        public let addDevice: String
    }
    
    public final class EcgSettings: Codable {
        public let ecgPreviewLabel: String
        public let ecgPreviewScreenTitle: String
        public let configureEcgIntervalTitle: String
        public let configureEcgFreqTitle: String
    }
    
    public final class AccessibilitySection: Codable {
        public let deviceConnected: String
        public let deviceDisconnected: String
        public let medicationAdded: String
        public let medicationEdited: String
    }
    
    public final class TrackIntakeSection: Codable {
        public let medication: String
        public let selectFromMedication: String
        public let trackIntakeNavTitle: String
        public let editIntakeNavTitle: String
        public let amountDate: String
        public let amount: String
        public let pills: String
        public let dailyReviewTitle: String
        public let intakeHistoryTitle: String
        public let selectMedicationNavTitle: String
        public let addMedicationBtnTitle: String
    }
    
    public final class ProfileSection: Codable {
        public let profileTitle: String
        public let accountDetailsCellTitle: String
        public let userInformationCellTitle: String
        public let termsAndCondCellTitle: String
        public let appSettingsCellTitle: String
        public let languageCellTitle: String
        public let helpCellTitle: String
        public let permissionsCellTitle: String
        public let voiceControlCellTitle: String
        public let siriShortcutsCellTitle: String
        public let deleteProfileAlertTitle: String
        public let deleteProfileAlertMessage: String
        public let deleteProfileBtnTitle: String
        public let languageScreentitle: String
        public let selectAppLanguage: String
        public let danishLanguage: String
        public let englishLanguage: String
    }
    
    public final class UserInformationSection: Codable {
        public let editNameTitle: String
        public let editBirthdayTitle: String
        public let editGenderTitle: String
        public let editWeightTitle: String
        public let editHeightTitle: String
        public let editMedicationListTitle: String
        public let userInformationTitle: String
        public let editNameDescription: String
        public let editBirthdayDescription: String
        public let editGenderDescription: String
        public let editWeightDescription: String
        public let editHeightDescription: String
        public let editMedicationListDescription: String
    }
    
    public final class HomeTabbarSection: Codable {
        public let dashboardTapviewTitle: String
        public let trackIntakeTapviewTitle: String
        public let profileTapviewTitle: String
    }
    
    public final class AddMedicationSection: Codable {
        public let currentMedicationTitle: String
        public let diagnosisTitle: String
        public let activeIngredients: String
        public let addActiveIngredientBtnTitle: String
        public let deleteMedicationBtnTitle: String
        public let addMedicationScreenTitle: String
        public let activeIngredientNameCellTitle: String
        public let countTFPrompt: String
        public let prickerSelectUnitTitle: String
    }
    
    public final class UserCreationSection: Codable {
        public let diagnosisTitle: String
        public let diagnosisInfo: String
        public let genderSelectionTitle: String
        public let genderSelectionInfo: String
        public let gettingStartedTitle: String
        public let gettingStartedInfo: String
        public let setupLaterBtnTitle: String
        public let setupLaterAlertTitle: String
        public let setupLaterAlertMessage: String
        public let heightSelectionTitle: String
        public let heightSelectionInfo: String
        public let heightTFPrompt: String
        public let weightSelectionTitle: String
        public let weightSelectionInfo: String
        public let weightTFPrompt: String
        public let medicationListSelectionTitle: String
        public let medicationListSelectionInfo: String
        public let personalIdentitySelectionTitle: String
        public let personalIdentitySelectionInfo: String
        public let personalIdentityPrompt: String
        public let birthdaySelectionSelectionTitle: String
        public let birthdaySelectionSelectionInfo: String
        public let birthdaySelectionIdentityPrompt: String
    }

}
