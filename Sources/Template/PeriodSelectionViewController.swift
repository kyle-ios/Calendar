//
//  PeriodSelectionViewController.swift
//  KakaoHealthcareCalendar
//
//  Created by kyle.cha on 2023/08/30.
//

import Foundation
import UIKit
import FSCalendar
import Combine

public final class PeriodSelectionViewController: UIViewController {
  // MARK: - Properties
  private let containerStatckView = UIStackView()
  private let calendarView: FSCalendar
  //    private var heightConstraint: Constraint?
  private var heightConstant: CGFloat?
  
  private let gradationView = UIView()
  
  private let confirmButton = UIButton(type: .system)
  private let cancelButton = UIButton(type: .system)
  
  private let dependencies: Dependencies
  
  private lazy var dataSource: PeriodSelectionDataSource = {
    PeriodSelectionDataSource(dependencies: dependencies)
  }()
  
  private let startDateSubject = CurrentValueSubject<Date?, Never>(nil)
  private let endDateSubject = CurrentValueSubject<Date?, Never>(nil)
  private let presentationTransitionDidEndSubject = PassthroughSubject<Void, Never>()
  private var cancellables = Set<AnyCancellable>()
  
  private let dateFormatter: DateFormatter = {
    let format = DateFormatter()
    format.locale = Locale(identifier: "ko_KR")
    
    return format
  }()
  
  public init(
    dependencies: Dependencies
  ) {
    self.dependencies = dependencies
    self.calendarView = FSCalendar(frame: .zero)
    
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    
    configureCalendar()
    bind()
  }
  
  public override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    
    if heightConstant != calendarView.collectionView.contentSize.height {
      calendarView.layoutIfNeeded()
      heightConstant = calendarView.collectionView.contentSize.height
      heightConstant
      //            heightConstraint?.update(offset: calendarView.collectionView.contentSize.height)
    }
    
    if dependencies.selectionType == .period,
       gradationView.layer.sublayers == nil {
      gradationView.layoutIfNeeded()
      
      //            gradationView
      //                .withGradientBackground(
      //                    top: .onSurfaceGradation.withAlphaComponent(0),
      //                    bottom: .onSurfaceGradation.withAlphaComponent(1)
      //                )
    }
  }
  
  public override func dismiss(
    animated flag: Bool,
    completion: (() -> Void)? = nil
  ) {
    super.dismiss(
      animated: flag
    ) {
      completion?()
    }
  }
  
  public override func loadView() {
    view = UIView()
    
    configureHeaderView()
    configureCalendarView()
    configureFeedbackView()
    
    view.addSubview(containerStatckView)
    containerStatckView.translatesAutoresizingMaskIntoConstraints = false
    
    NSLayoutConstraint.activate([
      containerStatckView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      containerStatckView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      containerStatckView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
      containerStatckView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
    ])
  }
  
  func bind() {
    bindSingleSelectionIfNeeded()
    bindPeriodSelectionIfNeeded()
  }
  
  func bindSingleSelectionIfNeeded() {
    guard dependencies.selectionType == .single else { return }
    // TODO
  }
  
  func bindPeriodSelectionIfNeeded() {
    guard dependencies.selectionType == .period else { return }
    
    cancelButton.publisher(forEvent: .touchUpInside)
      .sink { [weak self] in
        self?.dismiss()
      }
      .store(in: &cancellables)
    
    Publishers.CombineLatest(startDateSubject, endDateSubject)
      .drop(untilOutputFrom: presentationTransitionDidEndSubject)
      .handleEvents(receiveOutput: { [weak self] in
        self?.confirmButton.isEnabled = ($0.0.isNil.not && $0.1.isNil.not)
      })
      .sink(receiveValue: { [weak self] _ in
        self?.reloadVisibleCells()
      })
      .store(in: &cancellables)
    
    confirmButton.publisher(forEvent: .touchUpInside)
      .sink { [weak self] in
        guard let start = self?.startDateSubject.value,
              let end = self?.endDateSubject.value
        else {
          // something wrong case
          self?.confirmButton.isEnabled = false
          return
        }
        
        print("start : ", start)
        print("end : ", end)
        
        self?.dismiss()
      }
      .store(in: &cancellables)
  }
}

private extension PeriodSelectionViewController {
  func configureCalendar() {
    calendarView.delegate = self
    calendarView.dataSource = self
    //        calendarView.alpha = 0
    // disabled options
    calendarView.weekdayHeight = 0
    calendarView.placeholderType = .none
    calendarView.appearance.headerMinimumDissolvedAlpha = 0.0
    calendarView.appearance.headerSeparatorColor = .clear
    
    calendarView.scrollDirection = .vertical
    calendarView.rowHeight = 48
    calendarView.pagingEnabled = false
    calendarView.headerHeight = 40
    
    calendarView.appearance.headerDateFormat = "YYYY.MM"
    //    calendarView.appearance.headerTitleFont = .title3.regular
    calendarView.appearance.headerTitleAlignment = .left
    calendarView.appearance.headerTitleOffset = .init(x: 16, y: 8)
    
    calendarView.appearance.headerTitleColor = .black
    
    //    calendarView.appearance.titleFont = .body.regular
    //    calendarView.appearance.titleDefaultColor = .onSurface0
    //    calendarView.appearance.titleTodayColor = .onSurface0
    //    calendarView.appearance.titleSelectionColor = .onSurface0
    
    calendarView.contentView.clipsToBounds = false
    calendarView.daysContainer.clipsToBounds = false
    calendarView.collectionView.clipsToBounds = false
    
    calendarView.allowsMultipleSelection = dependencies.selectionType == .period
    calendarView.locale = Locale(identifier: "ko_KR")
    calendarView.register(
      PeriodSelectionCell.self,
      forCellReuseIdentifier: "PeriodSelectionCell"
    )
  }
  
  func configureHeaderView() {
    let wrpperView = UIView()
    
    let weekOfDaysStackView = UIStackView()
    weekOfDaysStackView.axis = .horizontal
    weekOfDaysStackView.distribution = .fillEqually
    
    let weekdays = Date.WeekDay.allCases.map {
      let label = UILabel()
      label.text = $0.localizedString
      label.font = .systemFont(ofSize: 12)
      label.textAlignment = .center
      label.adjustsFontForContentSizeCategory = true
      return label
    }
    
    weekdays.forEach { weekOfDaysStackView.addArrangedSubview($0) }
    wrpperView.addSubview(weekOfDaysStackView)
    
    weekOfDaysStackView.translatesAutoresizingMaskIntoConstraints = false
    
    NSLayoutConstraint.activate([
      weekOfDaysStackView.leadingAnchor.constraint(equalTo: wrpperView.leadingAnchor),
      weekOfDaysStackView.trailingAnchor.constraint(equalTo: wrpperView.trailingAnchor),
      weekOfDaysStackView.topAnchor.constraint(equalTo: wrpperView.topAnchor),
      weekOfDaysStackView.bottomAnchor.constraint(equalTo: wrpperView.bottomAnchor, constant: -8)
    ])
    
    containerStatckView.addArrangedSubview(weekOfDaysStackView)
  }
  
  func configureCalendarView() {
    let wrpperView = UIView()
    
    wrpperView.addSubview(calendarView)
    calendarView.translatesAutoresizingMaskIntoConstraints = false
    
    NSLayoutConstraint.activate([
      calendarView.leadingAnchor.constraint(equalTo: wrpperView.leadingAnchor),
      calendarView.trailingAnchor.constraint(equalTo: wrpperView.trailingAnchor),
      calendarView.topAnchor.constraint(equalTo: wrpperView.topAnchor),
      calendarView.bottomAnchor.constraint(equalTo: wrpperView.bottomAnchor, constant: -24)
    ])
    
    wrpperView.clipsToBounds = true
    containerStatckView.addArrangedSubview(wrpperView)
    
    if case .period = dependencies.selectionType {
      wrpperView.addSubview(gradationView)
      gradationView.translatesAutoresizingMaskIntoConstraints = false
      
      NSLayoutConstraint.activate([
        gradationView.leadingAnchor.constraint(equalTo: wrpperView.leadingAnchor),
        gradationView.trailingAnchor.constraint(equalTo: wrpperView.trailingAnchor),
        gradationView.bottomAnchor.constraint(equalTo: wrpperView.bottomAnchor),
        gradationView.heightAnchor.constraint(equalToConstant: 24)
      ])
    }
  }
  
  func configureFeedbackView() {
    guard dependencies.selectionType == .period else { return }
    
    let wrapperView = UIView()
    let stackView = UIStackView(arrangedSubviews: [cancelButton, confirmButton])
    confirmButton.setTitle("적용", for: .normal)
    confirmButton.titleLabel?.lineBreakMode = .byTruncatingTail
    confirmButton.contentEdgeInsets = UIEdgeInsets(top: 16, left: 24, bottom: 16, right: 24)
    
    
    cancelButton.setTitle("취소", for: .normal)
    cancelButton.titleLabel?.lineBreakMode = .byTruncatingTail
    cancelButton.contentEdgeInsets = UIEdgeInsets(top: 16, left: 24, bottom: 16, right: 24)
    
//    confirmButton.setBackgroundColor(color: UIColor.black, forState: .normal)
//    confirmButton.setBackgroundColor(color: .secondarySurface50, forState: .disabled)
    
    wrapperView.addSubview(stackView)
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.layer.cornerRadius = 24
    stackView.layer.borderWidth = 1
    stackView.layer.borderColor = UIColor.gray.cgColor
    
    NSLayoutConstraint.activate([
      stackView.leadingAnchor.constraint(equalTo: wrapperView.leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: wrapperView.trailingAnchor),
      stackView.bottomAnchor.constraint(equalTo: wrapperView.bottomAnchor),
      stackView.topAnchor.constraint(equalTo: wrapperView.topAnchor)
    ])
    
    stackView.axis = .horizontal
    stackView.distribution = .fillEqually
    
    confirmButton.isEnabled = false
    
    containerStatckView.addArrangedSubview(wrapperView)
  }
  
  func deselect(_ calendar: FSCalendar, date: Date?) {
    guard let date else { return }
    calendar.deselect(date)
  }
  
  func dismiss() {
    super.dismiss(
      animated: true
    ) { [weak self] in
      print("dismiss")
    }
  }
  
  func reloadVisibleCells() {
    calendarView.visibleCells().forEach {
      if let date = calendarView.date(for: $0) {
        ($0 as? PeriodSelectionCell)?.configure(
          with: dataSource.get(date),
          selection: configureSelection(at: date)
        )
      }
    }
  }
  
  func configureSelection(
    at date: Date
  ) -> PeriodSelectionCell.SelectionType? {
    let start = startDateSubject.value
    let end = endDateSubject.value
    
    if start == nil, end == nil {
      return nil
    }
    
    if let start, let end, start.isSameDay(from: end).not {
      return configureSelectionDirection(
        at: date,
        interval: start < end ? .init(start: start, end: end) : .init(start: end, end: start)
      )
    }
    
    if start?.isSameDay(from: date) == true {
      return .single
    }
    
    return nil
  }
  
  func configureSelectionDirection(
    at date: Date,
    interval: DateInterval
  ) -> PeriodSelectionCell.SelectionType? {
    guard interval.contains(date) else {
      return nil
    }
    
    if interval.start.isSameDay(from: date) {
      return .period(.left)
    }
    
    if interval.end.isSameDay(from: date) {
      return .period(.right)
    }
    
    return .period(.middle)
  }
}

// MARK: - FSCalendarDelegate
extension PeriodSelectionViewController: FSCalendarDelegate {
  public func calendar(
    _ calendar: FSCalendar,
    cellFor date: Date,
    at position: FSCalendarMonthPosition
  ) -> FSCalendarCell {
    let calendarCell = calendar.dequeueReusableCell(
      withIdentifier: "PeriodSelectionCell",
      for: date,
      at: position
    )
    
    guard let calendarCell = calendarCell as? PeriodSelectionCell else {
      return calendarCell
    }
    
    return calendarCell.configure(
      with: dataSource.get(date),
      selection: configureSelection(at: date)
    )
  }
  
  //    func calendar(
  //        _ calendar: FSCalendar,
  //        shouldSelect date: Date,
  //        at monthPosition: FSCalendarMonthPosition
  //    ) -> Bool {
  //        true
  //    }
  //
  //    func calendar(
  //        _ calendar: FSCalendar,
  //        shouldDeselect date: Date,
  //        at monthPosition: FSCalendarMonthPosition
  //    ) -> Bool {
  //        false
  //    }
  
  public func calendar(
    _ calendar: FSCalendar,
    didSelect date: Date,
    at monthPosition: FSCalendarMonthPosition
  ) {
    if endDateSubject.value != nil {
      deselect(calendar, date: startDateSubject.value)
      deselect(calendar, date: endDateSubject.value)
      
      endDateSubject.send(nil)
      startDateSubject.send(date)
      
    } else if startDateSubject.value == nil {
      startDateSubject.send(date)
      
    } else {
      endDateSubject.send(date)
    }
  }
}

// MARK: - FSCalendarDataSource
extension PeriodSelectionViewController: FSCalendarDataSource {
  public func minimumDate(for calendar: FSCalendar) -> Date {
    dependencies.calendarPeriod.start
  }
  
  public func maximumDate(for calendar: FSCalendar) -> Date {
    dependencies.calendarPeriod.end
  }
}

// MARK: - FSCalendarDelegateAppearance
//extension PeriodSelectionViewController: FSCalendarDelegateAppearance {
//  public func calendar(
//    _ calendar: FSCalendar,
//    appearance: FSCalendarAppearance,
//    titleDefaultColorFor date: Date
//  ) -> UIColor? {
////    guard dependencies.calendarPeriod.contains(date) else {
////      return .onSurface70
////    }
////
////    switch date.weekday() {
////    case .sunday:
////      return .primary
////    default:
////      return .onSurface0
////    }
//  }
//}

extension PeriodSelectionViewController {
  public enum SelectionType {
    case single
    case period
  }
  
  public enum PresentType {
    case push
    case present
    case bottomSheet
  }
  
  public struct Dependencies {
    let presentType: PresentType
    let selectionType: SelectionType
    let selectedDate: Date?
    // TBD: https://developer.apple.com/documentation/foundation/dateinterval
    let calendarPeriod: DateInterval
    let cgmWearingPeriod: [DateInterval]
    let alternateCgmDates: [Date]
    
    public init(
      presentType: PresentType = .bottomSheet,
      selectionType: SelectionType = .period,
      selectedDate: Date? = nil,
      calendarPeriod: DateInterval,
      cgmWearingPeriod: [DateInterval] = []
    ) {
      self.presentType = presentType
      self.selectionType = selectionType
      self.selectedDate = selectedDate
      self.calendarPeriod = calendarPeriod
      self.cgmWearingPeriod = cgmWearingPeriod
      self.alternateCgmDates = {
        guard cgmWearingPeriod.count > 1 else { return [] }
        return (0..<cgmWearingPeriod.count).compactMap { index -> Date? in
          let endDate = cgmWearingPeriod[index].end
          
//          if cgmWearingPeriod[safe: index + 1]?.start.isSameDay(from: endDate) ?? false {
//            return endDate
//          }
          
          return nil
        }
      }()
    }
  }
}


extension UIControl {
  func publisher(forEvent event: Event = .primaryActionTriggered) -> Publishers.Control {
    .init(control: self, event: event)
  }
}

extension Publishers {
  struct Control: Publisher {
    typealias Output = Void
    typealias Failure = Never
    
    private let control: UIControl
    private let event: UIControl.Event
    
    init(control: UIControl, event: UIControl.Event) {
      self.control = control
      self.event = event
    }
    
    func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Void == S.Input {
      subscriber.receive(subscription: Subscription(subscriber, control, event))
    }
    
    private class Subscription<S>: NSObject, Combine.Subscription where S: Subscriber, S.Input == Void, S.Failure == Never {
      private var subscriber: S?
      private weak var control: UIControl?
      private let event: UIControl.Event
      private var unconsumedDemand = Subscribers.Demand.none
      private var unconsumedEvents = 0
      
      init(_ subscriber: S, _ control: UIControl, _ event: UIControl.Event) {
        self.subscriber = subscriber
        self.control = control
        self.event = event
        super.init()
        
        control.addTarget(self, action: #selector(onEvent), for: event)
      }
      
      deinit {
        control?.removeTarget(self, action: #selector(onEvent), for: event)
      }
      
      func request(_ demand: Subscribers.Demand) {
        unconsumedDemand += demand
        consumeDemand()
      }
      
      func cancel() {
        subscriber = nil
      }
      
      private func consumeDemand() {
        while let subscriber = subscriber, unconsumedDemand > 0, unconsumedEvents > 0 {
          unconsumedDemand -= 1
          unconsumedEvents -= 1
          unconsumedDemand += subscriber.receive(())
        }
      }
      
      @objc private func onEvent() {
        unconsumedEvents += 1
        consumeDemand()
      }
    }
  }
}


public protocol AnyOptional {
  var isNil: Bool { get }
}

extension Optional: AnyOptional {
  public var isNil: Bool { self == nil }
}

public extension Bool {
  var toYNString: String {
    self ? "Y" : "N"
  }
  
  var toTrueFalseString: String {
    self ? "true" : "false"
  }
  
  var not: Bool {
    !self
  }
}
