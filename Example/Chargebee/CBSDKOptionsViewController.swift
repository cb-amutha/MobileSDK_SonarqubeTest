//
//  CBSDKOptionsViewController.swift
//  Chargebee
//
//  Created by cb-prabu on 07/07/2020.
//  Copyright (c) 2020 cb-prabu. All rights reserved.
//

import UIKit
import Chargebee

final class CBSDKOptionsViewController: UIViewController, UITextFieldDelegate {
    
    private var products: [CBProduct] = []
    private var items : [CBItemWrapper] = []
    private var plans : [CBPlan] = []

    private lazy var actions: [ClientAction] = [.initializeInApp,.getAllPlan, .getPlan, .getItems , .getItem, .getAddon, .createToken,.getProductIDs, .getProducts, .getSubscriptionStatus,]
    
    @IBOutlet private weak var tableView: UITableView! {
        didSet {
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        }
    }
}

extension CBSDKOptionsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        actions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = actions[indexPath.row].title
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // handle selection
        let selectedAction = actions[indexPath.row]
        switch  selectedAction {
        case .getPlan,
             .getAddon,
             .createToken,
             .getSubscriptionStatus,
             .initializeInApp,
             .processReceipt,
             .getItem:
            performSegue(withIdentifier: selectedAction.title, sender: self)
        case .getProductIDs:
            print("Get Product ID's")
            CBPurchase.shared.retrieveProductIdentifers(queryParams :["limit": "100"], completion:  { result in
                DispatchQueue.main.async {
                    switch result {
                    case let .success(dataWrapper):
                        debugPrint("items: \(dataWrapper)")
                        print(dataWrapper.ids)
                        DispatchQueue.main.async {
                            self.view.activityStopAnimating()
                            let alertController = UIAlertController(title: "Chargebee", message: "\(dataWrapper.ids.joined(separator:"\n"))", preferredStyle: .alert)
                            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                            self.present(alertController, animated: true, completion: nil)
                            
                        }

                    case let .failure(error):
                        debugPrint("Error: \(error.localizedDescription)")
                    }
                }
            })

        case .getProducts:
            let alert = UIAlertController(title: "",
                                          message: "Please enter Product id's (comma separated)",
                                          preferredStyle: UIAlertControllerStyle.alert)
            let defaultAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { (action) in
                if let textFields = alert.textFields, let customerTextField = textFields.first {
                    CBPurchase.shared.retrieveProducts(withProductID : customerTextField.text?.components(separatedBy: ",") ?? [String]() ,completion: { result in
                        DispatchQueue.main.async {
                            switch result {
                            case let .success(products):
                                self.products = products
                                debugPrint("products: \(products)")
                                self.performSegue(withIdentifier: "productList", sender: self)
                            case let .failure(error):
                                debugPrint("Error: \(error.localizedDescription)")
                            }
                        }
                    })
                }
            }
            defaultAction.isEnabled = true
            alert.addAction(defaultAction)
            alert.addTextField { (textField) in
                 textField.delegate = self
            }
            present(alert, animated: true, completion: nil)

            
        case .getItems:
            CBItem.retrieveAllItems(queryParams :["limit": "8","sort_by[desc]" : "name"], completion:  { result in
                DispatchQueue.main.async {
                    switch result {
                    case let .success(itemLst):
                        self.items =  itemLst.list
                        debugPrint("items: \(self.items)")
                        self.performSegue(withIdentifier: "itemList", sender: self)
                    case let .error(error):
                        debugPrint("Error: \(error.localizedDescription)")
                    }
                }
            })
        case .getAllPlan:
            print("List All Plans")
            CBPlan.retrieveAllPlans(queryParams: ["sort_by[desc]" : "name","channel[is]":"app_store"   ]) { result in
                switch result {
                case let .success(plansList):
                    var plans  = [CBPlan]()
                    for plan in  plansList.list {
                        plans.append(plan.plan)
                    }
                    self.plans = plans
                    debugPrint("items: \(self.plans)")
                    DispatchQueue.main.async {
                        let vc = CBSDKPlansViewController()
                        vc.render(self.plans)
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                    
                case let .error(error):
                    debugPrint("Error: \(error.localizedDescription)")
                }
            }
        }
    }
}

extension CBSDKOptionsViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "productList" {
            if let destinationVC = segue.destination as? CBSDKProductsTableViewController {
                destinationVC.products = self.products
            }
        } else if segue.identifier == "itemList" {
            if let destinationVC = segue.destination as?
                CBSDKItemsTableViewController {
                destinationVC.items = self.items
            }
        }
    }
    
}

enum ClientAction {
    case getPlan
    case getAllPlan
    case getAddon
    case createToken
    case initializeInApp
    case getProductIDs
    case getProducts
    case getSubscriptionStatus
    case processReceipt
    case getItems
    case getItem
}

extension ClientAction {
    var title: String {
        switch self {
        case .getAllPlan:
            return "Get Plans"
        case .getPlan:
            return "Get Plan"
        case .getAddon:
            return "Get Addon Details"
        case .createToken:
            return "Create Tokens"
        case .getProducts:
            return "Get Products"
        case .getSubscriptionStatus:
            return "Get Subscription Status"
        case .processReceipt:
            return "Verify Receipt"
        case .initializeInApp:
            return "Configure"
        case .getItems:
            return "Get Items"
        case .getItem:
            return "Get Item"
        case .getProductIDs:
            return "Get Apple Specific Product Identifiers"
        }
        
    }
}

extension String {
    var isNotEmpty: Bool {
        return !isEmpty
    }
}


@IBDesignable extension UIButton {
    
    @IBInspectable var borderWidth: CGFloat {
        set {
            layer.borderWidth = newValue
        }
        get {
            return layer.borderWidth
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat {
        set {
            layer.cornerRadius = newValue
        }
        get {
            return layer.cornerRadius
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        set {
            guard let uiColor = newValue else { return }
            layer.borderColor = uiColor.cgColor
        }
        get {
            guard let color = layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
    }
}


extension UIView{
    
    func activityStartAnimating(activityColor: UIColor, backgroundColor: UIColor) {
        let backgroundView = UIView()
        backgroundView.frame = CGRect.init(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height)
        backgroundView.backgroundColor = backgroundColor
        backgroundView.tag = 475647
        
        var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
        activityIndicator = UIActivityIndicatorView(frame: CGRect.init(x: 0, y: 0, width: 50, height: 50))
        activityIndicator.center = self.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        activityIndicator.color = activityColor
        activityIndicator.startAnimating()
        self.isUserInteractionEnabled = false
        
        backgroundView.addSubview(activityIndicator)
        
        self.addSubview(backgroundView)
    }
    
    func activityStopAnimating() {
        if let background = viewWithTag(475647){
            background.removeFromSuperview()
        }
        self.isUserInteractionEnabled = true
    }
}

