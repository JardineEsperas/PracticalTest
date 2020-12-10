//
//  BaseViewController.swift
//  tawk.to
//
//  Created by Marc Jardine Esperas on 12/9/20.
//

import UIKit
import Reachability

class BaseViewController: UIViewController {
    
    let reachability = try! Reachability()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureReachability()
    }
    
    func showAlert(title: String, message: String, style: UIAlertController.Style = .alert) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
        
        let action = UIAlertAction(title: "Close", style: .default) { (action) in
            self.dismiss(animated: true, completion: nil)
        }
        
        alertController.addAction(action)
        
        present(alertController, animated: true, completion: nil)
        
    }
    
    func createSpinnerFooter() -> UIView {
        
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 20))
        
        let spinner = UIActivityIndicatorView()
        
        spinner.center = footerView.center
        
        footerView.addSubview(spinner)
        
        spinner.startAnimating()
        
        return footerView
        
    }
    
    private func configureReachability() {


        NotificationCenter.default.addObserver(self, selector: #selector(self.reachabilityChanged(note: ) ), name: .reachabilityChanged, object: self.reachability)

        do {
            try reachability.startNotifier()
        } catch {
            print("Could not start notifier")
        }
        
    }
    
    @objc func reachabilityChanged(note: Notification) {
        
        let reachability = note.object as! Reachability
    
        if reachability.connection == .unavailable   {
            print("Network is not reachable")

        } else {
            print("Network is reachable")
            DispatchQueue.main.async {
                self.hasInternetConnection()
            }
            
        }
            
    }
    
    func hasInternetConnection() {
        
    }
    
}

