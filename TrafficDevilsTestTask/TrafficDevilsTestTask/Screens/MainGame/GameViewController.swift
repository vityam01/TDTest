//
//  GameViewController.swift
//  TrafficDevilsTestTask
//
//  Created by Vitya Mandryk on 10.02.2024.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load 'GameScene.sks' as a GKScene. This provides gameplay related content
        // including entities and graphs.
        if let scene = GKScene(fileNamed: "GameScene") {
            
            if let sceneNode = scene.rootNode as! GameScene? {
                sceneNode.delegateGame = self
                // Set the scale mode to scale to fit the window
                sceneNode.scaleMode = .aspectFill
                // Present the scene
                if let view = self.view as! SKView? {
                    view.presentScene(sceneNode)
                    view.ignoresSiblingOrder = true
                    view.showsFPS = true
                    view.showsNodeCount = true
                }
            }
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}


extension GameViewController: GameSceneDelegate {
    func showInternetController(url: URL) {
        let webViewController = ViewSource.showWebViewScreen()
        
        webViewController.urlToLoad = url
        webViewController.modalPresentationStyle = .fullScreen
        self.present(webViewController, animated: true)
    }
    
    func showPauseScreen() {
        let vc = ViewSource.gamePauseScreen()
//        vc.delegate = self
        vc.modalPresentationStyle = .overFullScreen
        NavigationController.shared?.present(vc, animated: false, completion: nil)
    }
}
