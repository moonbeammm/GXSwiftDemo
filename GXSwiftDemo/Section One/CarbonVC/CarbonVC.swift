//
//  CarbonVC.swift
//  GXSwiftDemo
//
//  Created by sgx on 2024/4/28.
//

import Combine
import UIKit
import Carbon

class CarbonVC: UIViewController {
    private lazy var flowLayout = {
        let t = UICollectionViewFlowLayout()
        t.minimumLineSpacing = 0
        t.minimumInteritemSpacing = 0
        t.sectionInset = .init(top: 16, left: 0, bottom: 0, right: 0)
        return t
    }()

    private lazy var collectionView = {
        let t = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        t.backgroundColor = .gray
        return t
    }()
    
    var list: [GXHeader] = {
        var sections: [GXHeader] = []
        for i in 0...100 {
            let header = GXHeader(title: "header \(i)")
            sections.append(header)
        }
        return sections
    }()
    
    private lazy var adapter = UICollectionViewFlowLayoutAdapter()
    private lazy var updater = UICollectionViewUpdater()
    private lazy var renderer = Renderer(adapter: adapter, updater: updater)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        view.addSubview(collectionView)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        renderer.target = collectionView
        
        render(list)
        
        let btn = UIButton(type: .custom)
        view.addSubview(btn)
        btn.frame = CGRect(x: 100, y: 100, width: 50, height: 50)
        btn.backgroundColor = .red
        btn.addTarget(self, action: #selector(btnClick), for: .touchUpInside)
        
        let time = ServerTime.shared.integerServerTime
        print("sgx >> \(time)")
    }
    
    private func render(_ sections: [GXHeader]) {
        renderer.render {
            
                for section in sections {
                    Section(id: "sections.hashValue", header: HeaderComponent(section))
                }
            
        }
    }
    
    @objc func btnClick() {
//        if let attrbutes = collectionView.layoutAttributesForSupplementaryElement(ofKind: UICollectionView.elementKindSectionHeader, at: IndexPath(row: NSNotFound, section: 1)) {
//            print("sgx >> \(attrbutes)")
//        } else if let attrbutes = collectionView.layoutAttributesForItem(at: IndexPath(row: NSNotFound, section: 1)) {
//            print("sgx >> \(attrbutes)")
//        }
        
        let header = collectionView.layoutAttributesForSupplementaryElement(ofKind: UICollectionView.elementKindSectionHeader, at: IndexPath(row: 1, section: 1))
        print("sgx >> \(header)")
        
        
        let attrbutes = collectionView.layoutAttributesForItem(at: IndexPath(row: NSNotFound, section: 1))
        print("sgx >> \(attrbutes)")
    }
}


//        render1 {
////            Section(id: section1.id, header: HeaderComponent(header1)) {
////                CellComponent(item: item1)
////            }
////            Group {
////                CellComponent(item: item1)
////            }
////            Group(of: section1.items) {
//                CellComponent(item: item1)
////            }
//        }
//        renderer.render {
//            Section(id: "0") {
//                CellComponent(item: item1)
//            }
//
//        }
        
        // cell
//        renderer.render {
//            Group {
//                CellComponent(item: item1)
//            }
//        }
//        renderer.render {
//            CellComponent(item: item1)
//            CellComponent(item: item2)
//            CellComponent(item: item3)
//        }
        // 最多10个section或cell
//        renderer.render {
//            Section(
//                id: 0,
//                header: HeaderComponent(header1))
//            {
//                CellComponent(item: item1)
//            }
//            Section(
//                id: 0,
//                header: HeaderComponent(header1))
//            {
//                CellComponent(item: item1)
//            }
//        }
//        // Group of可以打破10的限制
//        renderer.render {
//            Group (of: [item1,item1,item1,item1,item1,item1,item1,item1,item1,item1,item11]) { item in
//                CellComponent(item: item)
//            }
//        }
