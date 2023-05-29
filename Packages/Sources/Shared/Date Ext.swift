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
    
    static var dayMonthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM YYYY"
        return formatter
    }()
    
    static var hourMinuteFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    static var oldestPersonAlive: Date = {
        let calendar = Calendar.current
        let currentDate = Date()
        let oldestDateComponents = DateComponents(year: calendar.component(.year, from: currentDate) - 100)
        return calendar.date(from: oldestDateComponents)!
    }()
    
    func isSameDay(as otherDate: Date) -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: self)
        let otherComponents = calendar.dateComponents([.year, .month, .day], from: otherDate)
        
        return components.year == otherComponents.year && components.month == otherComponents.month && components.day == otherComponents.day
    }
}
