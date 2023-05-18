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
}
