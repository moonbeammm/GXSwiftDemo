//
//  GXSwipeVC.swift
//  GXSwiftDemo
//
//  Created by sgx on 2024/5/8.
//

import UIKit

class TableViewControllerDemo: UITableViewController {
    static var name: String { "TableViewController" }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "row")
        self.tableView.bounces = false
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "row", for: indexPath)
        cell.textLabel?.text = "Row \(indexPath.row)"
        return cell
    }
}

extension TableViewControllerDemo: RenderViewProtocol {
    func render() {
        tableView.reloadData()
    }
    func renderHeight() -> CGFloat {
        return tableView?.contentSize.height ?? 0
    }
}

class GXSwipeVC: UIViewController {
    lazy var moveView: UIView = {
        let t = UIView()
        t.backgroundColor = .blue
        return t
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let t = UIButton(type: .custom)
        t.backgroundColor = .red
        t.addTarget(self, action: #selector(btnclick), for: .touchUpInside)
        view.addSubview(t)
        t.frame = CGRect(x: 100, y: 200, width: 50, height: 50)
        
//        view.addSubview(moveView)
//        moveView.frame = CGRect(x: 200, y: 200, width: 50, height: 50)
    }
    @objc
    func btnclick() {
        let controller = TableViewControllerDemo()
        var options = SheetOptions()
        options.preferredHeight = { height in
            return controller.tableView.contentSize.height
        }
        let sheet = SheetViewController(
            controller: controller,
            sizes: [.intrinsic],
            options: options)
        sheet.animateIn(toView: self.view, inParentVC: self)
    }
}
