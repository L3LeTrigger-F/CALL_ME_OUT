import Foundation
import AVFoundation
import UIKit
import Combine

// MARK: - 铃声管理器
class RingtoneManager: ObservableObject {
    static let shared = RingtoneManager()
    
    @Published var isPlaying = false
    
    private var audioPlayer: AVAudioPlayer?
    private var ringtoneTimer: Timer?
    private var systemSoundID: SystemSoundID = 0
    
    private init() {
        print("⚙️ RingtoneManager 初始化")
    }
    
    // MARK: - 播放铃声
    func playRingtone() {
        print("\n🔔 ===== 开始播放铃声 =====")
        
        guard !isPlaying else {
            print("⚠️ 铃声已在播放中")
            return
        }
        
        // ⭐ 配置音频会话（关键步骤）
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // ⭐ 使用 .playback 类别，确保铃声能播放
            try audioSession.setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers, .duckOthers]
            )
            
            // ⭐ 激活音频会话
            try audioSession.setActive(true, options: [])
            
            print("✅ 音频会话已激活")
            print("📱 音频类别: \(audioSession.category)")
            print("📱 音频模式: \(audioSession.mode)")
            
        } catch {
            print("❌ 音频会话配置失败: \(error.localizedDescription)")
        }
        
        // ⭐ 尝试三种方式播放铃声
        var playSuccess = false
        
        // 方式1：尝试播放自定义音频文件
        if playCustomRingtone() {
            print("✅ 使用自定义铃声")
            playSuccess = true
        }
        // 方式2：使用系统音效循环
        else if playSystemSoundLoop() {
            print("✅ 使用系统音效")
            playSuccess = true
        }
        // 方式3：使用震动
        else {
            print("⚠️ 铃声播放失败，使用震动")
            startVibration()
            playSuccess = true
        }
        
        if playSuccess {
            isPlaying = true
            print("✅ 铃声播放已启动")
            print("============================\n")
        } else {
            print("❌ 所有铃声播放方式都失败")
        }
    }
    
    // MARK: - 方式1：播放自定义音频文件
    private func playCustomRingtone() -> Bool {
        // 尝试从 Bundle 加载铃声文件
        guard let soundURL = Bundle.main.url(forResource: "ringtone", withExtension: "mp3") ??
                            Bundle.main.url(forResource: "ringtone", withExtension: "wav") ??
                            Bundle.main.url(forResource: "ringtone", withExtension: "m4a") else {
            print("ℹ️ 未找到自定义铃声文件")
            return false
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.numberOfLoops = -1 // 无限循环
            audioPlayer?.volume = 1.0
            audioPlayer?.prepareToPlay()
            
            let success = audioPlayer?.play() ?? false
            if success {
                print("🎵 自定义铃声播放中")
                return true
            }
        } catch {
            print("❌ 自定义铃声播放失败: \(error.localizedDescription)")
        }
        
        return false
    }
    
    // MARK: - 方式2：使用系统音效循环
    private func playSystemSoundLoop() -> Bool {
        print("🔊 使用系统音效")
        
        // 使用系统铃声 ID
        // 1005 = 短信铃声，1007 = 邮件铃声
        systemSoundID = 1005
        
        // 立即播放一次
        AudioServicesPlaySystemSound(systemSoundID)
        
        // 每隔 1.5 秒播放一次
        ringtoneTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] timer in
            guard let self = self, self.isPlaying else {
                timer.invalidate()
                return
            }
            AudioServicesPlaySystemSound(self.systemSoundID)
            print("🔔 播放系统音效")
        }
        
        return true
    }
    
    // MARK: - 方式3：震动提醒
    private func startVibration() {
        // 震动
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        
        // 每隔 2 秒震动一次
        ringtoneTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] timer in
            guard let self = self, self.isPlaying else {
                timer.invalidate()
                return
            }
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            print("📳 震动")
        }
    }
    
    // MARK: - 停止铃声
    func stopRingtone() {
        print("\n🔕 ===== 停止铃声 =====")
        
        guard isPlaying else {
            print("⚠️ 铃声未在播放")
            return
        }
        
        // 停止音频播放器
        if let player = audioPlayer, player.isPlaying {
            player.stop()
            print("✅ 停止音频播放器")
        }
        audioPlayer = nil
        
        // 停止定时器
        ringtoneTimer?.invalidate()
        ringtoneTimer = nil
        print("✅ 停止定时器")
        
        // ⭐ 不要关闭音频会话，保持激活状态
        print("✅ 铃声已停止（音频会话保持激活）")
        print("============================\n")
        
        isPlaying = false
    }
    
    // MARK: - 清理资源
    deinit {
        stopRingtone()
    }
}
