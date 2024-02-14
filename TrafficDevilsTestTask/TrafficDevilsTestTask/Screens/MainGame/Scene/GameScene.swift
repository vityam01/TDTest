//
//  GameScene.swift
//  TrafficDevilsTestTask
//
//  Created by Vitya Mandryk on 10.02.2024.
//

import SpriteKit
import GameplayKit
import CoreMotion

protocol GameSceneDelegate: AnyObject {
    func showInternetController(url: URL)
    func showPauseScreen()
}
class GameScene: SKScene {
    
    //MARK: Variables
    // Labels
    private var gameTimerLabel: SKLabelNode!
    private var gameStartLabel: SKLabelNode!
    
    private var particleEmitter: SKEmitterNode?

    private var isGamePaused: Bool = false
    private var motionManager = CMMotionManager()
    private var gameTimer: Timer?
    private var winnerURL: URL?
    private var loserURL: URL?
    private var pausedTime: TimeInterval = 0
    private var gameSpentTime: Int = 0
    private var timer: Timer?
    private var firstStrip: Bool = true
    private var gameIsStarted: Bool = false
    
    private let ballCategory: UInt32 = 0x1 << 0
    private let obstacleCategory: UInt32 = 0x1 << 1
    private let wallCategory: UInt32 = 0x1 << 2
    private let ballFallSpeed: CGFloat = 1500.0
    
    private var holeWidth: CGFloat = 50
    private var triangleSize: CGFloat = 40
    
    private var touchedNode: SKNode?
    
    
    weak var delegateGame: GameSceneDelegate?
    
    
    private var ball: SKShapeNode = {
        let node = SKShapeNode(circleOfRadius: 20)
        node.name = "ball"
        node.fillColor = .systemIndigo
        node.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        node.physicsBody?.restitution = 0.0
        node.physicsBody?.linearDamping = 0.0
        node.physicsBody?.allowsRotation = false
        node.physicsBody?.categoryBitMask = 0x1 << 0
        node.physicsBody?.contactTestBitMask = 0x1 << 1
        
        return node
    }()
    
    
    
    //MARK: required init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        if let timerLabel = childNode(withName: App_Constants.Node_Names.gameTimerLabel) as? SKLabelNode {
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
    //MARK:
    override func didMove(to view: SKView) {
        setupTimerLabel()
        gameStartLabel?.text = "Tapp Image To Start"
        fetchWinnerLoserURLs()
        // game
        physicsWorld.contactDelegate = self
        ball.physicsBody?.velocity = CGVector(dx: 0, dy: -ballFallSpeed)
        particleEmitter = createParticleEmitter()
        if let emitter = particleEmitter {
            ball.addChild(emitter)
        }
        
        createWalls()
        setupAccelerometer()
    }
    
    //MARK: touchesBegan
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let nodeTouched = atPoint(location)
            let touchesNodes = self.nodes(at: location)
            
            if let nodeName = nodeTouched.name {
                switch nodeName {
                case App_Constants.Node_Names.startButton:
                    let fadeOut = SKAction.fadeOut(withDuration: 0.5)
                    let scaleDown = SKAction.scale(to: 0.1, duration: 0.5)
                    let groupAction = SKAction.group([fadeOut, scaleDown])
                    self.isPaused = false
                    childNode(withName: App_Constants.Node_Names.gameStartLabel)?.isHidden = true
                    childNode(withName: App_Constants.Node_Names.startButton)?.isHidden = true
                    addChild(ball)
                    createTriangels()
                    startStripGeneratorTimer()
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
    
    //MARK: touchesMoved
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    //MARK: touchesEnded
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
       
    }
    //MARK: touchesCancelled
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    //MARK: update
    override func update(_ currentTime: TimeInterval) {
        
    }
    
    
    //MARK: Private methods
    private func createParticleEmitter() -> SKEmitterNode {
        let emitter = SKEmitterNode(fileNamed: "DevilAnimation")
        emitter?.zPosition = ball.zPosition
        return emitter!
    }
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
        guard let gameTimer = gameTimer else { return }
        if isGamePaused {
            pausedTime = CACurrentMediaTime() - gameTimer.fireDate.timeIntervalSinceReferenceDate
            stopGameTimer()
        } else {
            createTriangels()
            startStripGeneratorTimer()
            startGameTimer()
            gameTimer.fireDate = Date(timeIntervalSinceReferenceDate: CACurrentMediaTime() - pausedTime)
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
        
    }
    
    private func setupTimerLabel() {
        gameTimerLabel = SKLabelNode(fontNamed: "Arial")
        gameTimerLabel.fontSize = 24
        gameTimerLabel.position = CGPoint(x: size.width / 2, y: size.height - 50)
        addChild(gameTimerLabel)
    }
    
    private func startGameTimer() {
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {return}
                self.gameSpentTime += 1
                (childNode(withName: App_Constants.Node_Names.gameTimerLabel) as? SKLabelNode)?.text = "Time: \(self.gameSpentTime)"
                if gameSpentTime >= 30 {
                    endGame()
                }
                print("Time: \(self.gameSpentTime)")
            }
        }
    }
    
    private func stopGameTimer() {
        gameTimer?.invalidate()
        gameTimer = nil
    }
    
    // MARK: Game
    
    private func endGame() {
        removeAllChildren()
        removeAllActions()
        self.isPaused = true
        timer?.invalidate()
        timer = nil
        gameTimer?.invalidate()
        gameTimer = nil
        gameIsStarted = false
        if gameSpentTime >= 30 {
            gameOver(isWinner: true)
            self.stopGameTimer()
        } else {
            gameOver(isWinner: false)
            self.stopGameTimer()
        }
        gameSpentTime = 0
    }
    
    func startGame() {
        guard gameIsStarted == false else {
            self.isPaused = false
            return }
        firstStrip = true
        self.isPaused = true
        ball.position = CGPoint(x: size.width / 2, y: size.height / 2)
        gameIsStarted = true
    }
    
    private func createWalls() {
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody?.restitution = 0.0
        physicsBody?.categoryBitMask = wallCategory
        physicsBody?.collisionBitMask = ballCategory
    }
    
    private func setupAccelerometer() {
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
            if let acceleration = data?.acceleration {
                self?.updateBallVelocity(acceleration: acceleration)
            }
        }
    }
    private func updateBallVelocity(acceleration: CMAcceleration) {
        let sensitivity: CGFloat = 750.0
        ball.physicsBody?.velocity.dx = CGFloat(acceleration.x) * sensitivity
    }
    
    private func startStripGeneratorTimer() {
        generateStripWithHole()
        timer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(generateStripWithHole), userInfo: nil, repeats: true)
    }
    
    @objc private func generateStripWithHole() {
        guard self.isPaused == false else { return }
        var moveRight = true
        let stripHeight: CGFloat = 5.0
        let stripWidth: CGFloat = size.width
        let holePosition = CGFloat.random(in: holeWidth / 2...(stripWidth - holeWidth / 2))
        let wallMoveSpeedCoefficient: CGFloat = 1.0 / 25.0
        var trianglePosX: CGFloat = 0
        var stripsMovementTimer: Timer?
        
        let leftStrip = SKSpriteNode(color: .white, size: CGSize(width: holePosition - holeWidth / 2, height: stripHeight))
        leftStrip.name = "strip"
        leftStrip.position = CGPoint(x: leftStrip.size.width / 2, y: -stripHeight / 2)
        setupStrip(strip: leftStrip)
        addChild(leftStrip)
        
        let rightStrip = SKSpriteNode(color: .white, size: CGSize(width: stripWidth - (holePosition + holeWidth / 2), height: stripHeight))
        rightStrip.name = "strip"
        rightStrip.position = CGPoint(x: size.width - rightStrip.size.width / 2, y: -stripHeight / 2)
        setupStrip(strip: rightStrip)
        addChild(rightStrip)
        
        let triangleOnStrip = DefaultRedShapeNode(size: triangleSize)
        triangleOnStrip.name = "triangleOnStrip"
        triangleOnStrip.zRotation = CGFloat.pi
        triangleOnStrip.physicsBody?.contactTestBitMask = self.ballCategory
        let triangleOnStripWidth = triangleOnStrip.frame.size.width
        if leftStrip.size.width >= triangleOnStripWidth && rightStrip.size.width >= triangleOnStripWidth {
            if Bool.random() == true {
                trianglePosX = CGFloat.random(in: triangleOnStripWidth / 2...(leftStrip.size.width - triangleOnStripWidth / 2))
            } else {
                trianglePosX = CGFloat.random(in: leftStrip.size.width + holeWidth + triangleOnStripWidth / 2...stripWidth - triangleOnStripWidth / 2)
            }
        } else if leftStrip.size.width >= triangleOnStripWidth {
            trianglePosX = CGFloat.random(in: triangleOnStripWidth / 2...(leftStrip.size.width - triangleOnStripWidth / 2))
        } else if rightStrip.size.width >= triangleOnStripWidth {
            trianglePosX = CGFloat.random(in: leftStrip.size.width + holeWidth + triangleOnStripWidth / 2...stripWidth - triangleOnStripWidth / 2)
        }
        triangleOnStrip.position = CGPoint(x: trianglePosX, y: triangleOnStrip.frame.size.height / 2)
        if firstStrip == false {
            addChild(triangleOnStrip)
        }
        
        let leftStripMoveUpAction = SKAction.move(by: CGVector(dx: 0, dy: size.height + stripHeight), duration: TimeInterval(size.height / (ballFallSpeed * wallMoveSpeedCoefficient)))
        let removeAction = SKAction.removeFromParent()
        leftStrip.run(SKAction.sequence([leftStripMoveUpAction, removeAction]))
        
        let rightStripMoveUpAction = SKAction.move(by: CGVector(dx: 0, dy: size.height + stripHeight), duration: TimeInterval(size.height / (ballFallSpeed * wallMoveSpeedCoefficient)))
        rightStrip.run(SKAction.sequence([rightStripMoveUpAction, removeAction]))
        
        let triangleOnStripMoveUpAction = SKAction.move(by: CGVector(dx: 0, dy: size.height + stripHeight), duration: TimeInterval(size.height / (ballFallSpeed * wallMoveSpeedCoefficient)))
        triangleOnStrip.run(SKAction.sequence([triangleOnStripMoveUpAction, removeAction]))
        
        stripsMovementTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(0.001), repeats: true) { timer in
            guard self.isPaused == false else { return }
            if moveRight == true {
                leftStrip.size.width += 0.1
                rightStrip.size.width -= 0.1
                
                leftStrip.position.x = leftStrip.size.width / 2
                rightStrip.position.x = self.size.width - rightStrip.size.width / 2
                triangleOnStrip.position.x += 0.1
                
                setupStrip(strip: leftStrip)
                setupStrip(strip: rightStrip)
                
                if rightStrip.size.width <= 0 {
                    moveRight = false
                }
            } else {
                leftStrip.size.width -= 0.1
                rightStrip.size.width += 0.1
                
                leftStrip.position.x = leftStrip.size.width / 2
                rightStrip.position.x = self.size.width - rightStrip.size.width / 2
                triangleOnStrip.position.x -= 0.1
                
                setupStrip(strip: leftStrip)
                setupStrip(strip: rightStrip)
                
                if leftStrip.size.width <= 0 {
                    moveRight = true
                }
            }
        }
        if triangleOnStrip.position.y >= Double((self.view?.frame.size.height ?? 0) - (self.view?.safeAreaInsets.top ?? 0)) {
            triangleOnStrip.removeFromParent()
        }
        
        Timer.scheduledTimer(withTimeInterval: TimeInterval(size.height / (ballFallSpeed * wallMoveSpeedCoefficient)), repeats: false) { timer in
            stripsMovementTimer?.invalidate()
            stripsMovementTimer = nil
        }
        
        firstStrip = false
        
        func setupStrip(strip: SKSpriteNode) {
            strip.physicsBody = SKPhysicsBody(rectangleOf: strip.size)
            strip.physicsBody?.categoryBitMask = self.obstacleCategory
            strip.physicsBody?.contactTestBitMask = self.ballCategory
            strip.physicsBody?.collisionBitMask = 0
            strip.physicsBody?.affectedByGravity = false
            strip.physicsBody?.allowsRotation = false
        }
    }
    
    
    private func createTriangels() {
        let screenWidth = size.width
        let screenHeight = size.height
        
        let numberOfTriangles = Int(screenWidth / triangleSize)
        
        let distanceBetweenTriangles = screenWidth / CGFloat(numberOfTriangles)
        
        for i in 0..<numberOfTriangles {
            let triangle = DefaultRedShapeNode(size: triangleSize)
            triangle.name = "triangle"
            
            let xPosition = CGFloat(i) * distanceBetweenTriangles + distanceBetweenTriangles / 2
            let yPosition = screenHeight - triangle.frame.size.height / 2 - (view?.safeAreaInsets.top ?? 0)
            
            triangle.position = CGPoint(x: xPosition, y: yPosition)
            
            addChild(triangle)
        }
    }
    
    deinit {
        motionManager.stopAccelerometerUpdates()
    }
    
    
}

// MARK: GamePauseDelegate
extension GameScene: GamePauseDelegate {
    func restartGame() {
        gameSpentTime = 0
        startGame()
    }
}


// MARK: SKPhysicsContactDelegate
extension GameScene: SKPhysicsContactDelegate {
    
    func didBegin(_ contact: SKPhysicsContact) {
        if (contact.bodyA.node?.name == "strip") && contact.bodyB.node?.name == "triangle" {
            contact.bodyA.node?.removeFromParent()
        } else if contact.bodyB.node?.name == "strip" && contact.bodyA.node?.name == "triangle" {
            contact.bodyB.node?.removeFromParent()
        }
        
        if contact.bodyA.node?.name == "ball" && (contact.bodyB.node?.name == "triangle" || contact.bodyB.node?.name == "triangleOnStrip") {
            endGame()
        } else if contact.bodyB.node?.name == "ball" && (contact.bodyA.node?.name == "triangle" || contact.bodyA.node?.name == "triangleOnStrip") {
            endGame()
        }
        
        if contact.bodyA.node?.name == "triangle" && contact.bodyB.node?.name == "triangleOnStrip" {
            contact.bodyB.node?.removeFromParent()
            
        } else if contact.bodyB.node?.name == "triangle" && contact.bodyA.node?.name == "triangleOnStrip" {
            contact.bodyA.node?.removeFromParent()
        }
    }
}

