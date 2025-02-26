//
//  SheetViewController+Helper.swift
//  GXSwiftDemo
//
//  Created by sgx on 2024/5/9.
//

import UIKit

extension SheetViewController {
    func configSubviews() {
        self.addMaskView()
        self.addContentView()
        self.addPanGestureRecognizer()
    }
    
    func addMaskView() {
        self.view.addSubview(self.maskView)
        self.maskView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.maskView.topAnchor.constraint(equalTo: view.topAnchor),
            self.maskView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            self.maskView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            self.maskView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        self.maskView.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(maskViewTapped))
        self.maskView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc 
    func maskViewTapped(_ gesture: UITapGestureRecognizer) {
        self.dismiss(animated: true)
    }

    func addContentView() {
        self.contentViewController.willMove(toParent: self)
        self.addChild(self.contentViewController)
        self.view.addSubview(self.contentViewController.view)
        self.contentViewController.didMove(toParent: self)
        self.contentViewController.delegate = self

        self.contentViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        let leadingContraint = self.contentViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        leadingContraint.priority = UILayoutPriority(999)
        leadingContraint.isActive = true
        let trailingContraint = self.contentViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        trailingContraint.priority = UILayoutPriority(999)
        trailingContraint.isActive = true
        let topContraint = self.contentViewController.view.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor)
        topContraint.priority = UILayoutPriority(999)
        topContraint.isActive = true
        let bottomContraint = self.contentViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        bottomContraint.priority = UILayoutPriority(999)
        bottomContraint.isActive = true
        
        self.contentViewHeightConstraint = self.contentViewController.view.heightAnchor.constraint(equalToConstant: self.height(for: self.currentSize))
        self.contentViewHeightConstraint?.isActive = true
    }
    
    func addPanGestureRecognizer() {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panned(_:)))
        self.contentViewController.view.addGestureRecognizer(panGestureRecognizer)
        panGestureRecognizer.delegate = self
        self.panGestureRecognizer = panGestureRecognizer
    }
    
    func updateThemeColor() {
        self.view.backgroundColor = UIColor.clear
        contentViewController.view.backgroundColor = .clear
        contentViewController.topBarView.backgroundColor = .clear
        contentViewController.childContainerView.backgroundColor = .clear
        
        maskView.backgroundColor = UIColor(white: 0, alpha: 0.25)
        contentViewController.contentView.backgroundColor = .white
        contentViewController.indicator.backgroundColor = .gray
        
        updateTheme(
            mask: maskView,
            container: contentViewController.contentView,
            indicator: contentViewController.indicator
        )
    }
}
