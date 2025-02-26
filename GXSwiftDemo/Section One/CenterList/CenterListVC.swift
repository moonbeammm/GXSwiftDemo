//
//  CenterListVC.swift
//  GXSwiftDemo
//
//  Created by 孙广鑫 on 2025/1/18.
//

import Foundation
import UIKit


//public class BBPlayerSettingListItem: NSObject {
//    var selected: Bool = false
//    var title: String?
//    var preferredSize: ((CGFloat) -> CGSize)?
//    var didSelectItemAt: ((IndexPath) -> Void)?
//}
//
//public class BBPlayerSettingListModel: NSObject {
//    var title: String?
//    var subTitle: String?
//    var height: CGFloat = 0
//    var minimumLineSpacingForSectionAt: ((Int) -> CGFloat)?
//    var minimumInteritemSpacingForSectionAt: ((Int) -> CGFloat)?
//    
//    var items: [BBPlayerSettingListItem] = []
//    
//}
//
//public class BBPlayerSettingListCell: UICollectionViewCell {
//    private lazy var titleLabel: UILabel = {
//        let v = UILabel()
//        v.font = UIFont.systemFont(ofSize: 15)
//        v.textColor = .white
//        return v
//    }()
//    public override init(frame: CGRect) {
//        super.init(frame: frame)
//        configSubviews()
//        self.contentView.backgroundColor = .red
//        self.contentView.layer.cornerRadius = 6
//        self.contentView.layer.masksToBounds = true
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    public func install(_ model: BBPlayerSettingListItem) {
//        titleLabel.text = model.title
//        if model.selected {
//            titleLabel.font = MainFont.font.T14b.font
//            titleLabel.theme_textColor(MainColor.Brand_pink.unchangedColor())
//        } else {
//            titleLabel.font = MainFont.font.T14.font
//            titleLabel.theme_textColor(MainColor.Text_white.unchangedColor())
//        }
//    }
//    func configSubviews() {
//        contentView.addSubview(titleLabel)
//        if let t = titleLabel.mas_makeConstraints() {
//            t.centerY.equalTo()(contentView)
//            t.left.equalTo()(contentView)?.offset()(16)
//            t.right.equalTo()(contentView)?.offset()(-16)
//            t.install()
//        }
//    }
//}
//
public class CenterListVC: UIViewController {
//    private lazy var titleLabel: UILabel = {
//        let v = UILabel()
//        v.font = MainFont.font.T14.font
//        v.theme_textColor(MainColor.Text_white.unchangedColor())
//        return v
//    }()
//    private lazy var subTitleLabel: UILabel = {
//        let v = UILabel()
//        v.font = MainFont.font.T12.font
//        v.theme_textColor(MainColor.Text2.unchangedColor())
//        return v
//    }()
//    private lazy var collectionView: UICollectionView = {
//        let t = UICollectionViewFlowLayout()
//        t.scrollDirection = .vertical
//        let v = UICollectionView(frame: .zero, collectionViewLayout: t)
//        v.backgroundColor = .clear
//        v.register(BBPlayerSettingListCell.self, forCellWithReuseIdentifier: "BBPlayerSettingListCell")
//        v.delegate = self
//        v.dataSource = self
//        return v
//    }()
//    
//    var model: BBPlayerSettingListModel?
//    
//    public init(context: BBPlayerContext, config: BBPlayerFloatingWidgetConfig?, model: BBPlayerSettingListModel) {
//        super.init(context: context, config: config)
//        if let style = config?.gradientStyle, style == .none {
//            view.backgroundColor = UIColor(white: 0, alpha: 0.88)
//        }
//        self.model = model
//        configSubViews()
//        install(model)
//    }
//    
//    func install(_ model: BBPlayerSettingListModel) {
//        titleLabel.text = model.title
//        subTitleLabel.text = model.subTitle
//        collectionView.reloadData()
//    }
}
//
//extension BBPlayerSettingListWidget {
//    func configSubViews() {
//        view.addSubview(titleLabel)
//        view.addSubview(subTitleLabel)
//        view.addSubview(collectionView)
//        if let t = titleLabel.mas_makeConstraints() {
//            t.top.mas_greaterThanOrEqualTo()(view)?.offset()(8)
//            t.left.equalTo()(view)
//            t.height.equalTo()(BBPlayerSettingListWidget.Constant.titleLabelHeight)
//            t.bottom.equalTo()(collectionView.mas_top)
//            t.install()
//        }
//        if let t = subTitleLabel.mas_makeConstraints() {
//            t.centerY.equalTo()(titleLabel.mas_centerY)
//            t.left.equalTo()(titleLabel.mas_right)?.offset()(4)
//            if let vertical = context?.status?.isVerticalScreen, vertical {
//                t.right.equalTo()(view)
//            } else {
//                t.right.equalTo()(view.mas_safeAreaLayoutGuideRight)
//            }
//            t.install()
//        }
//        if let t = collectionView.mas_makeConstraints() {
//            t.left.equalTo()(view)
//            t.centerY.equalTo()(view.mas_centerY)?.offset()(BBPlayerSettingListWidget.Constant.titleLabelHeight/2.0)?.priorityLow()
//            if let vertical = context?.status?.isVerticalScreen, vertical {
//                t.right.equalTo()(view)
//            } else {
//                t.right.equalTo()(view.mas_safeAreaLayoutGuideRight)
//            }
//            t.height.mas_equalTo()(model?.height ?? 0)?.priorityLow()
//            t.height.mas_lessThanOrEqualTo()(view.mas_height)?.offset()(-BBPlayerSettingListWidget.Constant.titleLabelHeight)?.priorityHigh()
//            t.install()
//        }
//    }
//}
//
//extension BBPlayerSettingListWidget: UICollectionViewDelegate, UICollectionViewDataSource {
//    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return model?.items.count ?? 0
//    }
//    
//    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BBPlayerSettingListCell", for: indexPath) as? BBPlayerSettingListCell,
//              let model = model?.items[safe: indexPath.row] else {
//            return BBPlayerSettingListCell()
//        }
//        cell.install(model)
//        return cell
//    }
//    
//    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        guard let item = model?.items[safe: indexPath.row] else { return }
//        self.navigationWidget?.pop(animated: true, competion: { [weak item] in
//            item?.didSelectItemAt?(indexPath)
//        })
//    }
//}
//
//extension BBPlayerSettingListWidget: UICollectionViewDelegateFlowLayout {
//    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        guard let model = model?.items[safe: indexPath.row] else { return .zero }
//        return model.preferredSize?(collectionView.bounds.width) ?? .zero
//    }
//    
//    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
//        guard let model = model else { return 0 }
//        return model.minimumLineSpacingForSectionAt?(section) ?? 0
//    }
//    
//    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
//        guard let model = model else { return 0 }
//        return model.minimumInteritemSpacingForSectionAt?(section) ?? 0
//    }
//    
//    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
//        
//    }
//    
//    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
//        
//    }
//}

