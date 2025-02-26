//
//  VKCheckmarkView.swift
//  BBVKUIKitSwift
//
//  Created by sgx on 2024/7/4.
//

import UIKit

public class VKCheckmarkView: UIView {
    public var startPoint: CGPoint = CGPoint(x: 0.32, y: 0.58) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public var midPoint: CGPoint = CGPoint(x: 0.45, y: 0.7) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public var endPoint: CGPoint = CGPoint(x: 0.79, y: 0.35) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public var checkmarkColor = UIColor.white {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public var circleColor = UIColor.systemPink {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
    }
    
    public override func draw(_ rect: CGRect) {
        // Draw the circle
        let circlePath = UIBezierPath(ovalIn: rect)
        circleColor.setFill()
        circlePath.fill()
        
        // Draw the checkmark with rounded corners
        let checkmarkPath = UIBezierPath()
        let start = CGPoint(x: rect.width * startPoint.x, y: rect.height * startPoint.y)
        let mid = CGPoint(x: rect.width * midPoint.x, y: rect.height * midPoint.y)
        let end = CGPoint(x: rect.width * endPoint.x, y: rect.height * endPoint.y)
        
        checkmarkPath.move(to: start)
        checkmarkPath.addLine(to: mid)
        checkmarkPath.addLine(to: end)
        
        // Add rounded corners to the checkmark path
        checkmarkPath.lineCapStyle = .round
        checkmarkPath.lineJoinStyle = .round
        checkmarkPath.lineWidth = rect.width * 1/15
        checkmarkColor.setStroke()
        checkmarkPath.stroke()
    }
}
