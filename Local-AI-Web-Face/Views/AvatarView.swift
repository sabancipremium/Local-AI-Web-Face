// AvatarView.swift
// Local-AI-Web-Face
//
// 2D Avatar display with SpriteKit animations

import SwiftUI
import SpriteKit
import Combine

// MARK: - Avatar Animation States

enum AvatarAnimationState {
    case idle
    case speaking
    case thinking
}

// MARK: - Avatar Scene

class AvatarScene: SKScene {
    private var avatarNode: SKSpriteNode?
    private var backgroundNode: SKSpriteNode?
    private var currentState: AvatarAnimationState = .idle
    private var ttsSubscription: AnyCancellable?
    
    // Animation textures (placeholders for now)
    private var idleTextures: [SKTexture] = []
    private var speakingTextures: [SKTexture] = []
    private var thinkingTextures: [SKTexture] = []
    
    override func didMove(to view: SKView) {
        setupScene()
        setupAvatar()
        loadTextures()
        startIdleAnimation()
    }
    
    private func setupScene() {
        backgroundColor = .clear
        scaleMode = .aspectFill
        
        // Add subtle background
        backgroundNode = SKSpriteNode(color: NSColor.controlBackgroundColor.withAlphaComponent(0.1), size: size)
        backgroundNode?.position = CGPoint(x: frame.midX, y: frame.midY)
        backgroundNode?.zPosition = -1
        if let backgroundNode = backgroundNode {
            addChild(backgroundNode)
        }
    }
    
    private func setupAvatar() {
        // Create avatar node with placeholder
        let avatarTexture = createPlaceholderTexture(color: .systemBlue, size: CGSize(width: 120, height: 120))
        avatarNode = SKSpriteNode(texture: avatarTexture)
        avatarNode?.position = CGPoint(x: frame.midX, y: frame.midY)
        avatarNode?.zPosition = 1
        
        if let avatarNode = avatarNode {
            addChild(avatarNode)
        }
    }
    
    private func loadTextures() {
        // For Phase 1, we'll use generated placeholder textures
        // In Phase 3, these would be loaded from actual avatar assets
        
        // Idle textures (different shades for animation)
        for i in 0..<4 {
            let alpha = 0.7 + (0.1 * Double(i))
            let texture = createPlaceholderTexture(
                color: NSColor.systemBlue.withAlphaComponent(alpha),
                size: CGSize(width: 120, height: 120)
            )
            idleTextures.append(texture)
        }
        
        // Speaking textures (warmer colors for speaking)
        for i in 0..<6 {
            let hue = 0.6 + (0.05 * Double(i)) // Blue to purple range
            let color = NSColor(hue: hue, saturation: 0.8, brightness: 0.9, alpha: 1.0)
            let texture = createPlaceholderTexture(color: color, size: CGSize(width: 120, height: 120))
            speakingTextures.append(texture)
        }
        
        // Thinking textures (cooler colors)
        for i in 0..<3 {
            let brightness = 0.5 + (0.2 * Double(i))
            let color = NSColor(hue: 0.7, saturation: 0.6, brightness: brightness, alpha: 1.0)
            let texture = createPlaceholderTexture(color: color, size: CGSize(width: 120, height: 120))
            thinkingTextures.append(texture)
        }
    }
    
    private func createPlaceholderTexture(color: NSColor, size: CGSize) -> SKTexture {
        let _ = NSGraphicsContext.current?.cgContext
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), 
                              bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, 
                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        
        context.setFillColor(color.cgColor)
        let rect = CGRect(origin: .zero, size: size)
        
        // Draw a circle
        context.fillEllipse(in: rect)
        
        // Add some visual interest - inner circle
        context.setFillColor(NSColor.white.withAlphaComponent(0.3).cgColor)
        let innerRect = rect.insetBy(dx: size.width * 0.3, dy: size.height * 0.3)
        context.fillEllipse(in: innerRect)
        
        let cgImage = context.makeImage()!
        let image = NSImage(cgImage: cgImage, size: size)
        return SKTexture(image: image)
    }
    
    // MARK: - Animation Methods
    
    func playAnimation(_ state: AvatarAnimationState) {
        guard currentState != state else { return }
        currentState = state
        avatarNode?.removeAllActions()
        
        switch state {
        case .idle:
            startIdleAnimation()
        case .speaking:
            startSpeakingAnimation()
        case .thinking:
            startThinkingAnimation()
        }
    }
    
    private func startIdleAnimation() {
        guard !idleTextures.isEmpty else { return }
        
        let animation = SKAction.animate(with: idleTextures, timePerFrame: 0.5)
        let repeatAnimation = SKAction.repeatForever(animation)
        
        // Add subtle floating motion
        let floatUp = SKAction.moveBy(x: 0, y: 5, duration: 2.0)
        let floatDown = SKAction.moveBy(x: 0, y: -5, duration: 2.0)
        floatUp.timingMode = .easeInEaseOut
        floatDown.timingMode = .easeInEaseOut
        let floatSequence = SKAction.sequence([floatUp, floatDown])
        let repeatFloat = SKAction.repeatForever(floatSequence)
        
        avatarNode?.run(repeatAnimation, withKey: "idle_animation")
        avatarNode?.run(repeatFloat, withKey: "idle_float")
    }
    
    private func startSpeakingAnimation() {
        guard !speakingTextures.isEmpty else { return }
        
        let animation = SKAction.animate(with: speakingTextures, timePerFrame: 0.12)
        let repeatAnimation = SKAction.repeatForever(animation)
        
        // Add pulsing scale effect
        let scaleUp = SKAction.scale(to: 1.05, duration: 0.3)
        let scaleDown = SKAction.scale(to: 0.98, duration: 0.3)
        scaleUp.timingMode = .easeInEaseOut
        scaleDown.timingMode = .easeInEaseOut
        let pulseSequence = SKAction.sequence([scaleUp, scaleDown])
        let repeatPulse = SKAction.repeatForever(pulseSequence)
        
        avatarNode?.run(repeatAnimation, withKey: "speaking_animation")
        avatarNode?.run(repeatPulse, withKey: "speaking_pulse")
    }
    
    private func startThinkingAnimation() {
        guard !thinkingTextures.isEmpty else { return }
        
        let animation = SKAction.animate(with: thinkingTextures, timePerFrame: 0.8)
        let repeatAnimation = SKAction.repeatForever(animation)
        
        // Add gentle rotation
        let rotateRight = SKAction.rotate(byAngle: 0.1, duration: 1.5)
        let rotateLeft = SKAction.rotate(byAngle: -0.2, duration: 3.0)
        let rotateBack = SKAction.rotate(byAngle: 0.1, duration: 1.5)
        rotateRight.timingMode = .easeInEaseOut
        rotateLeft.timingMode = .easeInEaseOut
        rotateBack.timingMode = .easeInEaseOut
        let rotateSequence = SKAction.sequence([rotateRight, rotateLeft, rotateBack])
        let repeatRotate = SKAction.repeatForever(rotateSequence)
        
        avatarNode?.run(repeatAnimation, withKey: "thinking_animation")
        avatarNode?.run(repeatRotate, withKey: "thinking_rotate")
    }
    
    func setupTTSObservation(ttsManager: TTSManager) {
        ttsSubscription = ttsManager.$isSpeaking.sink { [weak self] speaking in
            DispatchQueue.main.async {
                self?.playAnimation(speaking ? .speaking : .idle)
            }
        }
    }
    
    deinit {
        ttsSubscription?.cancel()
    }
}

// MARK: - Avatar View

struct AvatarView: View {
    @ObservedObject var ttsManager: TTSManager
    @State private var scene: AvatarScene
    
    init(ttsManager: TTSManager) {
        self.ttsManager = ttsManager
        let avatarScene = AvatarScene()
        avatarScene.size = CGSize(width: 280, height: 280)
        avatarScene.scaleMode = .aspectFill
        self._scene = State(initialValue: avatarScene)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Avatar Display
            SpriteView(scene: scene, options: [.allowsTransparency])
                .frame(width: 280, height: 280)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            // Avatar Status
            VStack(spacing: 8) {
                HStack {
                    Circle()
                        .fill(ttsManager.isSpeaking ? .green : .blue)
                        .frame(width: 8, height: 8)
                    
                    Text(ttsManager.isSpeaking ? "Speaking" : "Listening")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if ttsManager.isSpeaking {
                    Text("🎵")
                        .font(.title2)
                        .pulse()
                }
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            scene.setupTTSObservation(ttsManager: ttsManager)
        }
        .onChange(of: ttsManager.isSpeaking) { _, speaking in
            scene.playAnimation(speaking ? .speaking : .idle)
        }
    }
}

// MARK: - Preview

#Preview {
    AvatarView(ttsManager: TTSManager())
        .frame(width: 280, height: 400)
}
