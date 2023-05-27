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

public class IntakeHistoryViewModel: ObservableObject {
    @Published var intakes: [MedicationIntake] = []
}

public struct IntakeHistoryView: View {
    @ObservedObject var vm: IntakeHistoryViewModel
    
    public init(
        vm: IntakeHistoryViewModel
    ) {
        self.vm = vm
    }
    
    public var body: some View {
        VStack {
            ForEach(0 ..< vm.intakes.count) { index in
                HStack {
                    Image.pillIcon
                        .padding(.leading, 16)
                        .padding(.vertical, 16)
                    VStack(alignment: .leading) {
                        Text(vm.intakes[index].medication.name)
                            .font(.title1)
                            .foregroundColor(.black)
//                        if let subtitle = vm.subtitle {
//                            Text(subtitle)
//                                .font(.body1)
//                                .foregroundColor(.gray)
//                        }
                        
                    }
                    Spacer()
                    
                    Image.openIndicator
                        .padding(.trailing, 16)
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.background)
    }
}
