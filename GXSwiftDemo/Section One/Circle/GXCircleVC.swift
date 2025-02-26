//
//  GXCircleVC.swift
//  GXSwiftDemo
//
//  Created by sgx on 2024/5/8.
//

import UIKit

class GXCircleVC: UIViewController {

    
    
    // MARK: - Lifecycle

    let container = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
//        setupView()
        
//        let b = UIButton(type: .custom)
//        view.addSubview(b)
//        b.setImage(UIImage(named: "tv_icon"), for: .normal)
//        b.setTitle("哈哈", for: .normal)
//        b.backgroundColor = .red
//        b.translatesAutoresizingMaskIntoConstraints = false
//        b.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 100).isActive = true
//        b.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 100).isActive = true
//        
//        
//        
//        let b1 = UIButton(type: .custom)
//        view.addSubview(b1)
//        b1.setImage(UIImage(named: "tv_icon"), for: .normal)
//        b1.setTitle("哈111哈", for: .normal)
//        b1.backgroundColor = .red
//        b1.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 20, right: 20)
//        b1.translatesAutoresizingMaskIntoConstraints = false
//        b1.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 200).isActive = true
//        b1.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 100).isActive = true
//        
//   
//        
//        let label123 = UILabel()
//        label123.text = "1231123收到了封建势力党风建设老大腹肌是老大就撒溜达鸡算啦电极法算啦电极法算啦登记发啦生发剂"
//        label123.numberOfLines = 0
//        label123.font = UIFont.systemFont(ofSize: 5)
//        
//        let titleAttr = NSAttributedString(string: "123收到了封建势力党风建设老大腹肌是老大就撒溜达鸡算啦电极法算啦电极法算啦登记发啦生发剂", attributes: [
//            .font: UIFont.systemFont(ofSize: 24),
//            .foregroundColor: UIColor.red
//        ])
//        label123.attributedText = titleAttr
//        
//        view.addSubview(label123)
//        label123.translatesAutoresizingMaskIntoConstraints = false
//        label123.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 200).isActive = true
//        label123.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 200).isActive = true
//        label123.widthAnchor.constraint(equalToConstant: 100).isActive = true
        
        
//        let label1 = UILabel()
//        label1.text = "123"
//        
//        let button = UIButton(type: .custom)
//        button.setTitle("dslfa收到冷风机", for: .normal)
//        
//        let t = UIStackView()
//        t.axis = .vertical
//        t.distribution = .fill
//        t.alignment = .fill
//        t.backgroundColor = .blue
//        t.addArrangedSubview(label)
//        t.addArrangedSubview(label1)
//        t.addArrangedSubview(button)
//        
//        view.addSubview(t)
//        t.translatesAutoresizingMaskIntoConstraints = false
//        t.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 200).isActive = true
//        t.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 200).isActive = true
//        t.widthAnchor.constraint(equalToConstant: 100).isActive = true
        
        let mark = VKCheckmarkView()
        mark.startPoint = CGPoint(x: 0.32, y: 0.58)
        mark.midPoint = CGPoint(x: 0.45, y: 0.7)
        mark.endPoint = CGPoint(x: 0.79, y: 0.35)
        view.addSubview(mark)
        mark.translatesAutoresizingMaskIntoConstraints = false
        mark.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 200).isActive = true
        mark.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 200).isActive = true
        mark.widthAnchor.constraint(equalToConstant: 30).isActive = true
        mark.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        let mark1 = VKCheckmarkView()
        mark1.startPoint = CGPoint(x: 0.3, y: 0.55)
        mark1.midPoint = CGPoint(x: 0.45, y: 0.68)
        mark1.endPoint = CGPoint(x: 0.74, y: 0.38)
        view.addSubview(mark1)
        mark1.translatesAutoresizingMaskIntoConstraints = false
        mark1.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 200).isActive = true
        mark1.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 280).isActive = true
        mark1.widthAnchor.constraint(equalToConstant: 30).isActive = true
        mark1.heightAnchor.constraint(equalToConstant: 30).isActive = true
    }
//    public var startPoint: CGPoint = CGPoint(x: 0.32, y: 0.58) {
//        didSet {
//            setNeedsDisplay()
//        }
//    }
//    
//    public var midPoint: CGPoint = CGPoint(x: 0.45, y: 0.7) {
//        didSet {
//            setNeedsDisplay()
//        }
//    }
//    
//    public var endPoint: CGPoint = CGPoint(x: 0.79, y: 0.35) {
    // MARK: - Indeterminate Progress Examples

    lazy fileprivate var thinIndeterminate: RPCircularProgress = {
        let progress = RPCircularProgress()
        progress.thicknessRatio = 0.1
        return progress
    }()

    lazy fileprivate var thinFilledIndeterminate: RPCircularProgress = {
        let progress = RPCircularProgress()
        progress.innerTintColor = UIColor.red
        progress.thicknessRatio = 0.2
        progress.indeterminateDuration = 0.5
        return progress
    }()

    lazy fileprivate var unroundedIndeterminate: RPCircularProgress = {
        let progress = RPCircularProgress()
        progress.roundedCorners = false
        progress.thicknessRatio = 0.6
        progress.clockwiseProgress = false
        return progress
    }()

    lazy fileprivate var chartIndeterminate: RPCircularProgress = {
        let progress = RPCircularProgress()
        progress.roundedCorners = false
        progress.thicknessRatio = 1
        return progress
    }()

    // MARK: - Progress Examples

    lazy fileprivate var thinProgress: RPCircularProgress = {
        let progress = RPCircularProgress()
        progress.thicknessRatio = 0.2
        return progress
    }()

    lazy fileprivate var thinFilledProgress: RPCircularProgress = {
        let progress = RPCircularProgress()
        progress.trackTintColor = UIColor.init(red: 74 / 255, green: 144 / 255, blue: 226 / 255, alpha: 0.3)
        progress.progressTintColor = UIColor.init(red: 74 / 255, green: 144 / 255, blue: 226 / 255, alpha: 1)
        progress.thicknessRatio = 0.5
        return progress
    }()

    lazy fileprivate var unroundedProgress: RPCircularProgress = {
        let progress = RPCircularProgress()
        progress.roundedCorners = false
        progress.thicknessRatio = 0.3
        return progress
    }()

    lazy fileprivate var chartProgress: RPCircularProgress = {
        let progress = RPCircularProgress()
        progress.roundedCorners = false
        progress.thicknessRatio = 1
        return progress
    }()

}


private extension GXCircleVC {

    // MARK: - Constrain Views

    func setupView() {
        setupContainer()

//        setupThinIndeterminate()
//        setupThinFilledIndeterminate()
//        setupUnroundedIndeterminate()
//        setupChartIndeterminate()

//        setupThinProgress()
        setupThinFilledProgress()
//        setupUnroundedProgress()
//        setupChartProgress()
    }

    func setupContainer() {
        view.addSubview(container)
//        container.snp.makeConstraints { (make) in
//            make.center.equalTo(view)
//            make.width.equalTo(view).multipliedBy(0.8)
//            make.height.equalTo(view).multipliedBy(0.4)
//        }
        
        container.translatesAutoresizingMaskIntoConstraints = false
        container.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        container.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.4).isActive = true
        container.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        container.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }

    func setupThinIndeterminate() {
        constrain(thinIndeterminate)
        thinIndeterminate.enableIndeterminate()
    }

    func setupThinFilledIndeterminate() {
        constrain(thinFilledIndeterminate, leftView: thinIndeterminate)

        thinFilledIndeterminate.enableIndeterminate()
    }

    func setupUnroundedIndeterminate() {
        constrain(unroundedIndeterminate, leftView: thinFilledIndeterminate)

        unroundedIndeterminate.enableIndeterminate()
    }

    func setupChartIndeterminate() {
        constrain(chartIndeterminate, leftView: unroundedIndeterminate)

        chartIndeterminate.enableIndeterminate()
    }

    func setupThinProgress() {
        constrain(thinProgress, topView: thinIndeterminate)

        // You can update progress while being indeterminate if you'd like
        thinProgress.updateProgress(0.4, duration: 5)
        thinProgress.enableIndeterminate()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(2 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
            self.thinProgress.updateProgress(1, completion: {
                self.thinProgress.enableIndeterminate(false)
            })
        }
    }

    func setupThinFilledProgress() {
//        constrain(thinFilledProgress, leftView: thinProgress)
        container.addSubview(thinFilledProgress)
        thinFilledProgress.translatesAutoresizingMaskIntoConstraints = false
        thinFilledProgress.widthAnchor.constraint(equalToConstant: 40).isActive = true
        thinFilledProgress.heightAnchor.constraint(equalToConstant: 40).isActive = true
        thinFilledProgress.leftAnchor.constraint(equalTo: container.leftAnchor, constant: 20).isActive = true
        thinFilledProgress.topAnchor.constraint(equalTo: container.topAnchor, constant: 20).isActive = true
        thinFilledProgress.updateProgress(0.4, initialDelay: 0.4, duration: 3)
    }

    func setupUnroundedProgress() {
        constrain(unroundedProgress, leftView: thinFilledProgress)

        unroundedProgress.updateProgress(0.4, initialDelay: 0.6, duration: 4)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(2 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
            self.unroundedProgress.updateProgress(0.9)
        }
    }

    func setupChartProgress() {
        constrain(chartProgress, leftView: unroundedProgress)

        chartProgress.updateProgress(0.3, animated: false, initialDelay: 1)
    }

    // MARK: - Setup Helpers

    func constrain(_ newView: UIView, topView: UIView? = nil) {
        container.addSubview(newView)
//        newView.snp.makeConstraints { (make) in
//            make.size.equalTo(40)
//            make.left.equalTo(container).offset(20)
//            if let topView = topView {
//                make.top.equalTo(topView.snp.bottom).offset(20)
//            } else {
//                make.top.equalTo(container).offset(20)
//            }
//        }
        newView.translatesAutoresizingMaskIntoConstraints = false
        newView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        newView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        if let topView = topView {
            newView.topAnchor.constraint(equalTo: topView.bottomAnchor, constant: 20).isActive = true
        } else {
            newView.topAnchor.constraint(equalTo: container.topAnchor, constant: 20).isActive = true
        }
    }

    func constrain(_ newView: UIView, leftView: UIView) {
        container.addSubview(newView)
//        newView.snp.makeConstraints { (make) in
//            make.size.equalTo(40)
//            make.left.equalTo(leftView.snp.right).offset(20)
//            make.top.equalTo(leftView)
//        }
        newView.translatesAutoresizingMaskIntoConstraints = false
        newView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        newView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        newView.leftAnchor.constraint(equalTo: leftView.rightAnchor, constant: 20).isActive = true
        newView.topAnchor.constraint(equalTo: leftView.topAnchor).isActive = true
    }

}
