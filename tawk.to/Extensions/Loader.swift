//
//  Loader.swift
//  tawk.to
//
//  Created by Marc Jardine Esperas on 12/8/20.
//

import UIKit

fileprivate var aView: UIView?

extension UIViewController {
    
    func showSpinner() {
        
        aView = UIView(frame: self.view.bounds)
        aView?.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.8)
        
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = aView!.center
        activityIndicator.startAnimating()
        
        aView?.addSubview(activityIndicator)
        
        self.view.addSubview(aView!)
        
    }
    
    func removeSpinner() {
        
        aView?.removeFromSuperview()
        aView = nil
        
    }
    
}

