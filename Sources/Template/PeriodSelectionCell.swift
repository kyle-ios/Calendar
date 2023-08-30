//
//  PeriodSelectionCell.swift
//  KakaoHealthcareCalendar
//
//  Created by kyle.cha on 2023/08/30.
//

import Foundation
import UIKit
import FSCalendar

extension PeriodSelectionCell {
    enum BackgroundType {
        case normal
        case wearing(Direction)
        case alternateCgm
    }
    
    enum SelectionType {
        case single
        case period(Direction)
    }
    
    struct UIModel {
        let date: Date
        let backgroundType: BackgroundType
        let isToday: Bool
    }
  
    enum Direction {
        case left
        case middle
        case right
    }
}

final class PeriodSelectionCell: FSCalendarCell {
    private let wearingLayer = CAShapeLayer()
    private let todayLayer = CAShapeLayer()
    private let selectedLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUserInterface()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
//        titleLabel
//            .withReConstraints {
//                $0.top.equalToSuperview()
//                $0.bottom.equalToSuperview().inset(8)
//                $0.width.equalTo(contentView.snp.height)
//                $0.centerX.equalToSuperview()
//            }
    }
    
    @discardableResult
    func configure(
        with uiModel: UIModel,
        selection: SelectionType?
    ) -> Self {
        
        configureBackground(uiModel.backgroundType)
        configureSelection(selection)
        
        return self
    }
}

private extension PeriodSelectionCell {
    func setUserInterface() {
        shapeLayer.isHidden = true
        imageView.isHidden = true
        subtitleLabel.isHidden = true
        
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.adjustsFontSizeToFitWidth = true
        
        wearingLayer.fillColor = UIColor.gray.cgColor
        contentView.layer.insertSublayer(wearingLayer, below: titleLabel.layer)

        todayLayer.fillColor = UIColor.red.cgColor
        todayLayer.strokeColor = UIColor.black.cgColor
        contentView.layer.insertSublayer(todayLayer, below: titleLabel.layer)

        selectedLayer.fillColor = UIColor.systemBlue.cgColor
        selectedLayer.strokeColor = UIColor.systemBlue.cgColor
        
        contentView.layer.insertSublayer(selectedLayer, below: titleLabel.layer)
        titleLabel.textAlignment = .center
    }
    
    func configureBackground(_ backgroundType: BackgroundType) {
        wearingLayer.isHidden = false
        
        switch backgroundType {
        case .normal:
            wearingLayer.isHidden = true
            
        case .alternateCgm:
            wearingLayer.path = UIBezierPath(rect: titleLabel.bounds).cgPath
        
        case let .wearing(direction):
            wearingLayer.path = configureUIBezierPath(
                direction,
                fullRect: bounds,
                titleLabel: titleLabel
            ).cgPath
        }
    }
    
    func configureSelection(_ selectionType: SelectionType?) {
        guard let selectionType else {
            selectedLayer.isHidden = true
            return
        }
        
        switch selectionType {
        case .single:
            selectedLayer.path = UIBezierPath(
                arcCenter: titleLabel.center,
                radius: titleLabel.frame.height / 2,
                startAngle: CGFloat(0) * CGFloat.pi / 180.0,
                endAngle: CGFloat(360) * CGFloat.pi / 180.0,
                clockwise: true
            ).cgPath
            
        case .period(.middle):
            // TODO
            let path = UIBezierPath()
            path.move(to: .zero)
            path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.minY))
            path.move(to: CGPoint(x: bounds.maxX, y: titleLabel.bounds.maxY))
            path.addLine(to: CGPoint(x: bounds.minX, y: titleLabel.bounds.maxY))
            selectedLayer.path = path.cgPath
            wearingLayer.isHidden = true
            
        case let .period(direction):
            selectedLayer.path = configureUIBezierPath(
                direction,
                fullRect: bounds,
                titleLabel: titleLabel
            ).cgPath
        }
        
        selectedLayer.isHidden = false
    }
    
    func configureUIBezierPath(
        _ direction: Direction,
        fullRect: CGRect,
        titleLabel: UILabel
    ) -> UIBezierPath {
        let path = UIBezierPath()
        switch direction {
        case .left:
            path.move(to: CGPoint(
                x: fullRect.maxX,
                y: titleLabel.bounds.maxY)
            )
            
            path.addLine(to: CGPoint(x: titleLabel.center.x, y: titleLabel.bounds.maxY))
            
            path.addCurve(
                to: .init(x: titleLabel.center.x, y: titleLabel.bounds.minY),
                controlPoint1: .init(x: fullRect.minX, y: titleLabel.bounds.maxY),
                controlPoint2: .init(x: fullRect.minX, y: titleLabel.bounds.minY)
            )

            path.addLine(to: CGPoint(x: fullRect.maxX, y: titleLabel.bounds.minY))
            path.fill()
            
        case .right:
            path.move(to: CGPoint(
                x: fullRect.minX,
                y: titleLabel.bounds.minY)
            )
            
            path.addLine(to: CGPoint(x: titleLabel.center.x, y: titleLabel.bounds.minY))
            
            path.addCurve(
                to: .init(x: titleLabel.center.x, y: titleLabel.bounds.maxY),
                controlPoint1: .init(x: fullRect.maxX, y: titleLabel.bounds.minY),
                controlPoint2: .init(x: fullRect.maxX, y: titleLabel.bounds.maxY)
            )

            path.addLine(to: CGPoint(x: fullRect.minX, y: titleLabel.bounds.maxY))
            
            path.fill()
            
        case .middle:
            return UIBezierPath(
                rect: CGRect(
                    x: fullRect.minX,
                    y: titleLabel.bounds.minY,
                    width: fullRect.width,
                    height: titleLabel.bounds.height
                )
            )
        }
        
        return path
    }

}
