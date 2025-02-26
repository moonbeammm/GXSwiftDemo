//
//  Launch.swift
//  SpaceX Launch
//
//  Created by Puer on 2023/11/3.
//

import Foundation
import Carbon

//protocol ItemProtocol {
//    var component: (any Component)? { get }
//}
//protocol HeaderProtocol {
//    var component: (any Component)? { get }
//}
//protocol FooterProtocol {
//    var component: (any Component)? { get }
//}
//protocol SectionProtocol {
//    var id: String { get }
//    var items: [ItemProtocol] { get }
//    var header: HeaderProtocol? { get }
//    var footer: FooterProtocol? { get }
//}




struct GXHeader {
    var title: String = ""
    var component: (any Component)?
}
struct GXFooter {
    var title: String = ""
    var component: (any Component)?
}
struct GXItem {
    var title: String = ""
    var component: (any Component)?
}
struct GXSection {
    var id: String = UUID().uuidString
    var title: String = ""
    var items: [GXItem] = []
    var header: GXHeader?
    var footer: GXFooter?
}
