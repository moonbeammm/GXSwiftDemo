//
//  SheetViewController+DisplayLink.swift
//  GXSwiftDemo
//
//  Created by sgx on 2024/5/9.
//

import UIKit

extension SheetViewController {
    public func startFrameAnimation() {
        displayLastTime = CACurrentMediaTime()*1000
        if displayLink == nil {
            displayLink = CADisplayLink.init(target: self, selector: #selector(upateFrame))
            displayLink?.add(to: RunLoop.main, forMode: .common)
        }
        displayLink?.isPaused = false
    }
    
    public func stopFrameAnimation() {
        displayLink?.isPaused = true
        let rect = self.contentViewController.view.layer.bounds
        
        rectChanged(frame: rect, offset: 0)
    }
    
    @objc private func upateFrame() {
        let currentTime = CACurrentMediaTime() * 1000
        let rect = self.contentViewController.view.layer.presentation()?.bounds ?? self.contentViewController.view.layer.bounds
        //过滤突变
        if currentTime - displayLastTime <= 50 && rect.equalTo(self.contentViewController.view.layer.bounds) {
            return
        }
        rectChanged(frame: rect, offset: 0)
    }
}
