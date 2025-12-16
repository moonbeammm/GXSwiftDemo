//
//  ViewController.swift
//  GXSwiftDemo
//
//  Created by sgx on 2024/4/19.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }

    private func setupUI() {
        let feedButton = UIButton(type: .system)
        feedButton.setTitle("打开小红书列表", for: .normal)
        feedButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        feedButton.addTarget(self, action: #selector(openFeedList), for: .touchUpInside)
        feedButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(feedButton)

        NSLayoutConstraint.activate([
            feedButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            feedButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc private func openFeedList() {
        let feedListVC = FeedListViewController()
        let navController = UINavigationController(rootViewController: feedListVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
}

