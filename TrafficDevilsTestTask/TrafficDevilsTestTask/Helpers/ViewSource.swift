//
//  ViewSource.swift
//  TrafficDevilsTestTask
//
//  Created by Vitya Mandryk on 10.02.2024.
//

import Foundation
import UIKit

class ViewSource: NSObject {
    
    static var startStoryboard  = UIStoryboard(name: "Main", bundle: Bundle.main)
    
    static func mainScreen() -> GameViewController {
        return UIStoryboard.getViewController(storyboard: "Main",
                                              identifier: "GameViewController") as! GameViewController
    }
    
    static func gamePauseScreen() -> GamePauseViewController1 {
        return startStoryboard.instantiateViewController(withIdentifier: "GamePauseViewController1") as! GamePauseViewController1
    }
    
    static func showWebViewScreen() -> InternetController {
        return startStoryboard.instantiateViewController(withIdentifier: "InternetController")  as! InternetController
    }
}

