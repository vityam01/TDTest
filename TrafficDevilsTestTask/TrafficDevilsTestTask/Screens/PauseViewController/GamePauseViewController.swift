//
//  GamePauseViewController.swift
//  TrafficDevilsTestTask
//
//  Created by Vitya Mandryk on 10.02.2024.
//

import Foundation
import UIKit


protocol GamePauseDelegate {
    
    func restartGame()
    
}
    


class GamePauseViewController1: UIViewController {
    
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var restartBtn: UIButton!
    @IBOutlet private weak var tapToExitHint: UILabel!
    
    var delegate: GamePauseDelegate?
    
    private var isRestart = false
    
    override func viewDidLoad() {
        initUI()
    }
    
    
    private func initUI() {
        let backgroundSwipe = UISwipeGestureRecognizer(target: self, action: #selector(self.backgroundViewTapped(_:)))
        let backgroundTap = UITapGestureRecognizer(target: self, action: #selector(self.backgroundViewTapped(_:)))
        backgroundSwipe.direction = .up
        backgroundView.addGestureRecognizer(backgroundSwipe)
        backgroundView.addGestureRecognizer(backgroundTap)
        backgroundView.isUserInteractionEnabled = true
                
        tapToExitHint.text = tapToExitHint.text
        Animation.shared.animateBlinkingHint(tapToExitHint, startAfter: 0.5)
    }
    
    private func presentGameScreen() {
        dismiss(animated: true, completion: nil)
    }
    
    private func restartGame() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "restart"), object: nil)
        delegate?.restartGame()
        presentGameScreen()
    }
    
    @objc func backgroundViewTapped(_ sender: Any) {
        presentGameScreen()
    }
    
    @IBAction private func restartBtnTapped(_ sender: UIButton) {
        isRestart = true
    }
}
