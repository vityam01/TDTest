//
//  Animation.swift
//  TrafficDevilsTestTask
//
//  Created by Vitya Mandryk on 10.02.2024.
//

import Foundation
import UIKit

class Animation {
    static let shared = Animation()
    
    func animateBlinkingHint(_ view: UIView, startAfter deadline: Double) {
        DispatchQueue.main.asyncAfter(deadline: .now() + deadline) {
            UIView.animate(withDuration: 1.5, delay: 0, options: [.autoreverse, .repeat], animations: {
                view.alpha = 0
            })
        }
    }
}

