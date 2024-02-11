//
//  UIStoryboard.swift
//  TrafficDevilsTestTask
//
//  Created by Vitya Mandryk on 10.02.2024.
//

import Foundation
import UIKit

extension UIStoryboard {
    
    static func getViewController(storyboard: String, identifier: String) -> UIViewController {
        let sb = UIStoryboard(name: storyboard, bundle: nil)
        return sb.instantiateViewController(withIdentifier: identifier)
    }
}
