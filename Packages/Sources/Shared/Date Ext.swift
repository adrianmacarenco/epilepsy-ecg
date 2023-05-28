//
//  File 2.swift
//  
//
//  Created by Adrian Macarenco on 28/05/2023.
//

import Foundation


public extension Date {
    static var dayMonthHourMinuteFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM HH:mm"
        return formatter
    }()
    
    static var hourMinuteFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}
