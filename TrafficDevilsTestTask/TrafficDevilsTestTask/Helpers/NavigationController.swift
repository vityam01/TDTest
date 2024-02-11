//
//  NavigationController.swift
//  TrafficDevilsTestTask
//
//  Created by Vitya Mandryk on 10.02.2024.
//

import Foundation
import UIKit

class NavigationController: UINavigationController {

    static private(set) var shared: NavigationController? = nil
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        NavigationController.shared = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setNavigationBarHidden(true, animated: false)
        setupInitialController()
    }

    // MARK: - Public.
    @objc func setRoot(_ vc: UIViewController, animated: Bool) {
        if topViewController == vc {
            // Do not switch controller if it's already onscreen.
            return
        }
        self.setViewControllers([vc], animated: animated)
    }
    
    func getCurrentViewController() -> UIViewController? {
        return topViewController
    }

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: animated)
    }
    
    override func popViewController(animated: Bool) -> UIViewController? {
        return super.popViewController(animated: animated)
    }

    // MARK: - Private Methods
    
    private func setupInitialController() {
        setRoot(ViewSource.mainScreen(), animated: true)
    }
}


