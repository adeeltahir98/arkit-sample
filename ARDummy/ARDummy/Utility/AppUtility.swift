//
//  AppUtility.swift
//  ARDummy
//
//  Created by Adeel Tahir on 27/12/2022.
//

import Foundation
import UIKit

class AppUtility {
    static let shared = AppUtility()
    private init() {}
    
    func getRoundyButton(size: CGFloat = 100,
                         imageName : String,
                         _ colorTop : UIColor ,
                         _ colorBottom : UIColor ) -> UIButton {
        
        let button = UIButton(frame: CGRect.init(x: 0, y: 0, width: size, height: size))
        button.clipsToBounds = true
        button.layer.cornerRadius = size / 2
        
        let gradient: CAGradientLayer = CAGradientLayer()
        
        gradient.colors = [colorTop.cgColor, colorBottom.cgColor]
        gradient.startPoint = CGPoint(x: 1.0, y: 1.0)
        gradient.endPoint = CGPoint(x: 0.0, y: 0.0)
        gradient.frame = button.bounds
        gradient.cornerRadius = size / 2
        
        button.layer.insertSublayer(gradient, at: 0)
        
        let image = UIImage.init(named: imageName )
        let imgView = UIImageView.init(image: image)
        imgView.center = CGPoint.init(x: button.bounds.size.width / 2.0, y: button.bounds.size.height / 2.0 )
        button.addSubview(imgView)
        
        return button
        
    }
}
