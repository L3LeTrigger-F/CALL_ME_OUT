import AVFoundation
import MediaPlayer
import Combine
import UIKit

class VolumeButtonManager: NSObject, ObservableObject {  // ✅ 添加 NSObject 继承
    static let shared = VolumeButtonManager()
    
    @Published var shouldTriggerCall = false
    
    private var volumeView: MPVolumeView?
    private var audioSession: AVAudioSession?
    private var initialVolume: Float = 0.5
    private var lastVolumeChangeTime: Date?
    
    private let doubleClickThreshold: TimeInterval = 0.5 // 双击时间间隔
    private var clickCount = 0
    private var resetTimer: Timer?
    
    private override init() {  // ✅ 添加 override
        super.init()  // ✅ 调用父类初始化
        setupAudioSession()
        setupVolumeView()
        startObservingVolume()
    }
    
    // MARK: - Setup Audio Session
    private func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession?.setActive(true)
            initialVolume = audioSession?.outputVolume ?? 0.5
        } catch {
            print("音频会话设置失败: \(error)")
        }
    }
    
    // MARK: - Setup Volume View
    private func setupVolumeView() {
        volumeView = MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 1, height: 1))
    }
    
    // MARK: - Observe Volume
    private func startObservingVolume() {
        audioSession?.addObserver(
            self,
            forKeyPath: "outputVolume",
            options: [.new, .old],
            context: nil
        )
    }
    
    // ✅ 添加 override
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if keyPath == "outputVolume" {
            guard let newVolume = change?[.newKey] as? Float,
                  let oldVolume = change?[.oldKey] as? Float else {
                return
            }
            
            // 检测到音量变化
            if newVolume != oldVolume {
                handleVolumeChange()
            }
        }
    }
    
    // MARK: - Handle Volume Change
    private func handleVolumeChange() {
        let now = Date()
        
        // 恢复音量到初始值
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            self.setSystemVolume(self.initialVolume)
        }
        
        // 检测双击
        if let lastTime = lastVolumeChangeTime {
            let timeSinceLastClick = now.timeIntervalSince(lastTime)
            
            if timeSinceLastClick < doubleClickThreshold {
                clickCount += 1
                
                if clickCount >= 1 { // 第二次点击
                    triggerCall()
                    resetClickTracking()
                    return
                }
            } else {
                // 超时，重置计数
                clickCount = 1
            }
        } else {
            clickCount = 1
        }
        
        lastVolumeChangeTime = now
        
        // 设置重置定时器
        resetTimer?.invalidate()
        resetTimer = Timer.scheduledTimer(
            withTimeInterval: doubleClickThreshold,
            repeats: false
        ) { [weak self] _ in
            self?.resetClickTracking()
        }
    }
    
    // MARK: - Trigger Call
    private func triggerCall() {
        print("✅ 检测到双击音量键，触发来电！")
        
        // 触发来电
        DispatchQueue.main.async {
            self.shouldTriggerCall = true
            
            // 延迟重置状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.shouldTriggerCall = false
            }
        }
        
        // 震动反馈
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    // MARK: - Reset Tracking
    private func resetClickTracking() {
        clickCount = 0
        lastVolumeChangeTime = nil
        resetTimer?.invalidate()
    }
    
    // MARK: - Set System Volume
    private func setSystemVolume(_ volume: Float) {
        let volumeView = MPVolumeView()
        if let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                slider.value = volume
            }
        }
    }
    
    // MARK: - Cleanup
    func stopObserving() {
        audioSession?.removeObserver(self, forKeyPath: "outputVolume")
        resetTimer?.invalidate()
    }
    
    deinit {
        stopObserving()
    }
}
