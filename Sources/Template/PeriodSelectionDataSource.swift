//
//  PeriodSelectionDataSource.swift
//  KakaoHealthcareCalendar
//
//  Created by kyle.cha on 2023/08/30.
//

import Foundation

struct PeriodSelectionDataSource {
    typealias DictionaryType = [Date: PeriodSelectionCell.UIModel]
    private var dictionary: DictionaryType
    private let dependencies: PeriodSelectionViewController.Dependencies
    private let todayDate = Date()
    
    init(dependencies: PeriodSelectionViewController.Dependencies) {
        self.dependencies = dependencies
        self.dictionary = [:]
    }
}

extension PeriodSelectionDataSource: Collection {
    
    typealias Index = DictionaryType.Index
    typealias Element = DictionaryType.Element
    
    var startIndex: Index { dictionary.startIndex }
    var endIndex: Index { dictionary.endIndex }
    
    subscript(index: Index) -> Iterator.Element {
        dictionary[index]
    }
    
    func index(
        after index: DictionaryType.Index
    ) -> DictionaryType.Index {
        dictionary.index(after: index)
    }
}

extension PeriodSelectionDataSource {
    mutating func get(_ key: DictionaryType.Key) -> DictionaryType.Value {
        if let value = dictionary[key] {
            return value
        }
        
        let value = toUIModel(key: key)
        dictionary.updateValue(value, forKey: key)
        return value
    }
}

private extension PeriodSelectionDataSource {
    func toUIModel(key date: DictionaryType.Key) -> DictionaryType.Value {
        DictionaryType.Value(
            date: date,
            backgroundType: configureBackground(key: date),
            isToday: todayDate.isSameDay(from: date)
        )
    }
    
    func configureBackground(
        key date: DictionaryType.Key
    ) -> PeriodSelectionCell.BackgroundType {
        
        for period in dependencies.cgmWearingPeriod {
            guard period.contains(date) else { continue }
            
            if dependencies.alternateCgmDates.contains(date) {
                return .alternateCgm
            }
                
            if period.start.isSameDay(from: date) {
                return .wearing(.left)
            }
            
            if period.end.isSameDay(from: date) {
                return .wearing(.right)
            }
            
            return .wearing(.middle)
        }
        return .normal
    }
    
//    func configureCellType(key date: DictionaryType.Key) -> AirCalendarCell.MarkerType {
//        if let selectedDate = dependencies.selectedDate,
//           date.isSameDay(from: selectedDate) {
//            return .selectedSingle
//        }
//
//        if dependencies.alternateCgmDates.contains(date) {
//            return .alternateCgm
//        }
//
//        if date.isSameDay(from: todayDate) {
//            return .today
//        }
//
//        if
//
//        return .normal
//    }
}

// MARK: - Comparable
public extension Date {
    func distance(
        from date: Date,
        component: Calendar.Component,
        calendar: Calendar = .current
    ) -> Int? {
        calendar.dateComponents([component], from: self, to: date).value(for: component)
    }

    func isSameDay(from date: Date) -> Bool {
        distance(from: date, component: .day) == 0
    }
    
    func startOfMonth(using calendar: Calendar = .current) -> Date? {
        calendar.dateComponents([.calendar, .year, .month], from: self).date
    }
    
    func startOfNextMonth(
        using calendar: Calendar = .current
    ) -> Date? {
        guard let startDay = startOfMonth(using: calendar) else { return nil }
        return calendar.date(byAdding: .month, value: 1, to: startDay)
    }
    
    func weekdayValue(using calendar: Calendar = .current) -> Int {
        calendar.component(.weekday, from: self)
    }
    
    func weekday() -> WeekDay? {
        WeekDay(rawValue: weekdayValue())
    }
    
    enum WeekDay: Int, CaseIterable {
        case sunday = 1
        case monday = 2
        case tuesday = 3
        case wednesday = 4
        case thursday = 5
        case friday = 6
        case saturday = 7
        
        public var localizedString: String {
            switch self {
            case .sunday: return "일"
            case .monday: return "월"
            case .tuesday: return "화"
            case .wednesday: return "수"
            case .thursday: return "목"
            case .friday: return "금"
            case .saturday: return "토"
            }
        }
    }
}

