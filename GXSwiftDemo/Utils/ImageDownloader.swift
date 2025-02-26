//
//  ImageDownloader.swift
//  SpaceX Launch
//
//  Created by Puer on 2023/11/3.
//

import Combine
import UIKit

class ImageDownloader {
    // MARK: Internal

    static let shared = ImageDownloader()

    func download(_ url: URL, completion: @escaping (Result<(URL, UIImage), Error>) -> Void) {
        if let image = images[url] { completion(.success((url, image))) }
        guard cancellables[url] == nil else {
            pendingCallbacks[url] = completion
            return
        }

        let cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .compactMap { UIImage(data: $0) }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in completion(.failure(NSError(domain: "", code: 0, userInfo: nil))) },
                receiveValue: { [weak self] in
                    self?.images[url] = $0
                    self?.cancellables[url] = nil
                    completion(.success((url, $0)))
                }
            )
        cancellables[url] = cancellable
    }

    // MARK: Private

    private var images: [URL: UIImage] = [:]

    private var cancellables: [URL: Cancellable] = [:]

    private var pendingCallbacks: [URL: (Result<(URL, UIImage), Error>) -> Void] = [:]
}
