//
//  GameScene.swift
//  TrafficDevilsTestTask
//
//  Created by Vitya Mandryk on 10.02.2024.
//

import SpriteKit
import GameplayKit

protocol GameSceneDelegate: AnyObject {
    func showInternetController(url: URL)
    func showPauseScreen()
}
class GameScene: SKScene {
    
    //MARK: Variables
    // Labels
    private var gameTimerLabel: SKLabelNode!
    private var gameStartLabel: SKLabelNode!
    
    
    private var isGamePaused: Bool = false

    private var gameTimeCounter: Int = 30
    private var gameTimer: Timer?
    private var winnerURL: URL?
    private var loserURL: URL?
    
    // Game
    private var platforms: [SKShapeNode] = []
    private var obstacles: [SKShapeNode] = []
    private var ball: SKShapeNode!

    weak var delegateGame: GameSceneDelegate?
    
    
    
    //MARK: required init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        if let timerLabel = childNode(withName: App_Constants.Node_Names.gameTimerLabel) as? SKLabelNode {
            timerLabel.text = "Time: \(self.gameTimeCounter)"
            gameTimerLabel = timerLabel
        } else {
            print("Error: Unable to find gameTimerLabel")
        }
        
        if let startLabel = childNode(withName: App_Constants.Node_Names.gameStartLabel) as? SKLabelNode {
            gameStartLabel = startLabel
        } else {
            print("Error: Unable to find gameStartLabel")
        }
        
    }
    
    //MARK: Lifesycle of Scene
    override func didMove(to view: SKView) {
        setupTimerLabel()
        gameStartLabel?.text = "Tapp Image To Start"
        fetchWinnerLoserURLs()
        // game
        createBall()
        createBallFromTop()
        createPlatforms()
        createObstacle()
        animateBall()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let nodeTouched = atPoint(location)
            let touchesNodes = self.nodes(at: location)
            
            if let nodeName = nodeTouched.name {
                switch nodeName {
                case App_Constants.Node_Names.startButton:
                    childNode(withName: App_Constants.Node_Names.gameStartLabel)?.isHidden = true
                    childNode(withName: App_Constants.Node_Names.startButton)?.isHidden = true
                    startGameTimer()
                case App_Constants.Node_Names.pauseButton:
                    togglePauseGame()
                    showPauseView()
                default:
                    break
                }
            }
            
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let ball = ball else { return }
        let touchLocation = touch.location(in: self)
        let previousLocation = touch.previousLocation(in: self)
        let touchDelta = touchLocation.x - previousLocation.x
        
        let moveAction = SKAction.move(by: CGVector(dx: touchDelta, dy: 0), duration: 0.1)
        ball.run(moveAction)
    }

    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
         
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        if !isGamePaused {
            movePlatforms()
            moveObstacles()
            checkCollisions()
        }
    }
    
    
    //MARK: Private methods
    
    // Rest API
    private func fetchWinnerLoserURLs() {
        guard let url = URL(string: App_Constants.App_Links.mainUrlForParsing) else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching URLs: \(error)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
                self.winnerURL = URL(string: apiResponse.winner)
                self.loserURL = URL(string: apiResponse.loser)
            } catch {
                print("Error decoding JSON: \(error)")
            }
        }.resume()
    }
    
    private func togglePauseGame() {
        isGamePaused.toggle()
        if isGamePaused {
            stopGameTimer()
        } else {
            startGameTimer()
        }
    }
    
    private func gameOver(isWinner: Bool) {
        let webViewController = ViewSource.showWebViewScreen()
        webViewController.modalPresentationStyle = .fullScreen
        var url = URL(string: "")
        if isWinner {
            url = winnerURL ?? URL(string: App_Constants.App_Links.defaultLink)!
        } else {
            url = loserURL ?? URL(string: App_Constants.App_Links.defaultLink)!
        }
        webViewController.urlToLoad = url
        delegateGame?.showInternetController(url: url ?? URL(string: App_Constants.App_Links.defaultLink)!)
    }

    private func showPauseView() {
        delegateGame?.showPauseScreen()
//        let vc = ViewSource.gamePauseScreen()
//        vc.delegate = self
//        vc.modalPresentationStyle = .overFullScreen
//        NavigationController.shared?.present(vc, animated: false, completion: nil)
    }
    
    private func setupTimerLabel() {
        gameTimerLabel = SKLabelNode(fontNamed: "Arial")
        gameTimerLabel.fontSize = 24
        gameTimerLabel.position = CGPoint(x: size.width / 2, y: size.height - 50)
        updateTimerLabel()
        print(gameTimeCounter)
        addChild(gameTimerLabel)
    }
    
    private func startGameTimer() {
        gameTimeCounter = 30
        updateTimerLabel()
        gameTimer = Timer.scheduledTimer(timeInterval: 1.0,
                                         target: self,
                                         selector: #selector(updateTimer),
                                         userInfo: nil,
                                         repeats: true)
    }
    
    private func updateTimerLabel() {
        gameTimerLabel.text = "Time: \(gameTimeCounter)"
    }

    
    @objc private func updateTimer() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if self.gameTimeCounter > 0 {
                self.gameTimeCounter -= 1
                print("Time: \(gameTimeCounter)")
                updateTimerLabel()
            } else if self.gameTimeCounter <= 0 {
                gameOver(isWinner: false)
                self.stopGameTimer()
            }
        }
    }
    
    private func stopGameTimer() {
        gameTimer?.invalidate()
        gameTimer = nil
    }
    
    // MARK: Game
    
    private func createBallFromTop() {
        guard let ball = ball else { return }
        let initialBallPosition = CGPoint(x: size.width / 2, y: size.height - ball.frame.size.height)
        ball.position = initialBallPosition
    }
    
    private func createPlatform() {
        let platformWidth: CGFloat = 100.0
        let platformHeight: CGFloat = 20.0
        let platformColor = SKColor.green

        let platform = SKShapeNode(rectOf: CGSize(width: platformWidth, height: platformHeight))
        platform.fillColor = platformColor
        platform.strokeColor = platformColor
        platform.position = CGPoint(x: CGFloat.random(in: platformWidth...(size.width - platformWidth)), y: -platformHeight)

        addChild(platform)
        platforms.append(platform)
    }

    private func movePlatforms() {
        for platform in platforms {
            let moveAction = SKAction.move(by: CGVector(dx: 0, dy: 25), duration: 1.0)
            platform.run(moveAction)
            
            // Check if platform is at the top, remove it and end the game
            if platform.position.y > size.height {
                platform.removeFromParent()
                platforms.removeAll { $0 == platform }
//                gameOver(isWinner: false)
                stopGameTimer()
            }
        }
    }

    private func createObstacle() {
        
        let obstacleWidth: CGFloat = 50.0
        let obstacleHeight: CGFloat = 50.0
        let obstacleColor = SKColor.red

        let obstacle = SKShapeNode(rectOf: CGSize(width: obstacleWidth, height: obstacleHeight))
        obstacle.fillColor = obstacleColor
        obstacle.strokeColor = obstacleColor
        obstacle.position = CGPoint(x: CGFloat.random(in: 0...(size.width - obstacleWidth)), y: -obstacleHeight)
        
        
        addChild(obstacle)
        obstacles.append(obstacle)
        
    }

    private func moveObstacles() {
        for obstacle in obstacles {
            let moveAction = SKAction.move(by: CGVector(dx: 0, dy: 25), duration: 1.0)
            obstacle.run(moveAction)
        }
    }

    private func createBall() {
        let ballRadius: CGFloat = 25.0
        let ballColor = SKColor.blue

        ball = SKShapeNode(circleOfRadius: ballRadius)
        ball.fillColor = ballColor
        ball.strokeColor = ballColor
        ball.position = CGPoint(x: size.width / 2, y: size.height - ballRadius * 2)
        
        addChild(ball)
    }
    
    private func animateBall() {
        let bounceAction = SKAction.sequence([
            SKAction.move(by: CGVector(dx: 0, dy: -50), duration: 0.5),
            SKAction.move(by: CGVector(dx: 0, dy: 50), duration: 0.5)
        ])
        let bounceForever = SKAction.repeatForever(bounceAction)
        ball.run(bounceForever)
    }
    
    private func checkCollisions() {
        if let ball = ball {
            // Check collisions with obstacles
            for obstacle in obstacles {
                if ball.intersects(obstacle) {
//                    gameOver(isWinner: false)
                    stopGameTimer()
                    return
                }
            }
            
            // Check collisions with platforms
            for platform in platforms {
                if ball.intersects(platform) {
                    if platform.fillColor == SKColor.red {
//                        gameOver(isWinner: false)
                        stopGameTimer()
                    }
                    // Handle collision with other platforms if needed
                }
            }
            
            // Check if ball reaches the top of the screen
            if ball.position.y > size.height {
//                gameOver(isWinner: false)
                stopGameTimer()
            }
        }
    }
    
    private func createPlatforms() {
        let createPlatformAction = SKAction.sequence([
            SKAction.run { [weak self] in
                self?.createPlatform()
            },
            SKAction.wait(forDuration: 2.0)
        ])

        let createPlatformForever = SKAction.repeatForever(createPlatformAction)
        run(createPlatformForever)
    }
    
}


// MARK: GamePauseDelegate
extension GameScene: GamePauseDelegate {
    func restartGame() {
        // TODO: need to emplement
    }
}


