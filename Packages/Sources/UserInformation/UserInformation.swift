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
import Dependencies
import SwiftUINavigation

public class UserInformationViewModel: ObservableObject {
    @Published var components = Component.allCases
    @Published var user: User
    @Dependency (\.dbClient) var dbClient
    @Dependency (\.persistenceClient) var persistenceClient
    
    public init(
        user: User
    ) {
        self.user = user
    }
    
    func componentTapped(index: Int) {
        
    }
}

extension UserInformationViewModel {
    public enum Component: String, CaseIterable {
        case fullName = "Full name"
        case birthday = "Birthday"
        case gender = "Gender"
        case weight = "Weight"
        case height = "Height"
        case currentMedications = "Current medications"
        
        public func description(user: User) -> String? {
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
                return nil
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
                        description: vm.components[index].description(user: vm.user),
                        title: vm.components[index].rawValue
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        vm.componentTapped(index: index)
                    }
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 16)
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
