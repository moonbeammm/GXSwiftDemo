//
//  Decoder.swift
//  SpaceX Launch
//
//  Created by Puer on 2023/11/3.
//

import Foundation

extension JSONDecoder {
    static func decoder() -> JSONDecoder {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .secondsSince1970
        return jsonDecoder
    }
}
