//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 22/06/2023.
//

import Foundation
import Combine
import SwiftUI
import StylePackage
import Localizations
import Dependencies
import PersistenceClient

public class LanguageSelectionViewModel: ObservableObject {
    let languages = LanguageType.allCases
    @Published var selectedLanguage: LanguageType
    @Dependency (\.localizations) var localizations
    @Dependency (\.persistenceClient) var persistenceClient

    init(cachedLanguage: String) {
        if let selectedLanguage = LanguageType(rawValue: cachedLanguage) {
            self.selectedLanguage = selectedLanguage
        } else {
            self.selectedLanguage = .english
        }
    }
    
    func didTapLanguageCell(_ index: Int) {
        guard index < languages.count, let observableLanguageType = ObservableLocalizations.LanguageType(rawValue: languages[index].localizationsIdentifier()) else { return }
        selectedLanguage = languages[index]
        localizations.updateLocalization(with: observableLanguageType)
        persistenceClient.selectedLanguage.save(observableLanguageType.rawValue)
    }
}

extension LanguageSelectionViewModel {
    enum LanguageType: String, CaseIterable {
        case english = "en"
        case danish = "da"
        
        func localizationsIdentifier() -> String {
            switch self {
            case .english:
                return "en"
            case .danish:
                return "da"
            }
        }
        func getLocalizedTitle(localizations: Localizations.ProfileSection) -> String {
            switch self {
            case .english:
                return localizations.englishLanguage
            case .danish:
                return localizations.danishLanguage
            }
        }
    }
}

public struct LanguageSelectionView: View {
    @ObservedObject var vm: LanguageSelectionViewModel
    @EnvironmentObject var localizations: ObservableLocalizations

    public init(vm: LanguageSelectionViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        VStack {
            Text(localizations.profileSection.selectAppLanguage)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .font(.headline2)
                .foregroundColor(.black)
            ForEach(0 ..< vm.languages.count, id: \.self) { index in
                LanguageCell(
                    title: vm.languages[index].getLocalizedTitle(localizations: localizations.profileSection),
                    vm: .init(isSelected: vm.selectedLanguage == vm.languages[index])
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    vm.didTapLanguageCell(index)
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
        .background(Color.background)
        .navigationTitle(localizations.profileSection.languageScreentitle)
    }
}


class LanguageCellViewModel: ObservableObject {
    @Published var isSelected: Bool
    
    init(isSelected: Bool) {
        self.isSelected = isSelected
    }
}

struct LanguageCell: View {
    let title: String
    @ObservedObject var vm: LanguageCellViewModel
    
    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .font(.title1)
                    .foregroundColor(.black)
                Spacer()
                if vm.isSelected {
                    Image.checkedIcon
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

