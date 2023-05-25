//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 25/05/2023.
//

import Foundation
import SwiftUI
import Combine
import StylePackage

public class AddMedicationViewModel: ObservableObject {
    
}

public struct AddMedicationView: View {
    @ObservedObject var vm: AddMedicationViewModel
    
    public init(
        vm: AddMedicationViewModel
    ) {
        self.vm = vm
    }
    
    public var body: some View {
        VStack {
            
        }
    }
}
