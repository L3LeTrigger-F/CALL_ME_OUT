// MARK: - AI 通话管理器（修复音频冲突版）

import Foundation
import SwiftUI
import SwiftData
import AVFoundation
import Speech
import Combine

@MainActor
class AICallManager: ObservableObject {
    static let shared = AICallManager()
    
    @Published var isAIEnabled = false
    @Published var conversationMessages: [ConversationMessage] = []
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var isRecording = false
    @Published var currentAudioLevel: Float = 0.0
    @Published var recognizedText: String = ""
    
    private let miniMaxService = MiniMaxVoiceService.shared
    
    private var audioLevelTimer: Timer?
    private var silenceTimer: Timer?
    
    // 语音识别（统一使用 AVAudioEngine）
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // ⭐ 音量监测变量
    private var currentPower: Float = -160.0  // 当前音量（分贝）
    
    // 静音检测配置
    private let silenceThreshold: Float = -30.0      // 调整阈值
    private let silenceDuration: TimeInterval = 1.5  // 增加到 1.5 秒
    private var lastSoundTime: Date = Date()
    private var hasSpokeOnce: Bool = false
    private var continuousSilenceCount: Int = 0
    
    private init() {
        print("⚙️ AICallManager 初始化")
    }
    
    // MARK: - 初始化 AI 通话
    func initializeAICallWithAutoRecording(scenario: CallScenario, customText: String = "") async {
        print("\n🎬 ===== 初始化 AI 通话 =====")
        print("📋 场景: \(scenario.rawValue)")
        
        let micAuthorized = await requestMicrophonePermission()
        let speechAuthorized = await requestSpeechRecognitionPermission()
        
        guard micAuthorized && speechAuthorized else {
            errorMessage = "需要麦克风和语音识别权限"
            print("❌ 权限不足")
            return
        }
        
        print("✅ 权限已获取")
        
        miniMaxService.setupScenario(scenario, customText: customText)
        
        conversationMessages = []
        isAIEnabled = true
        
        print("🎯 开始生成 AI 开场白...")
        await generateAIGreeting()
        
        print("🎙️ 准备开始自动录音...")
        await startAutoRecording()
        
        print("===========================\n")
    }
    
    // MARK: - 请求权限
    private func requestMicrophonePermission() async -> Bool {
        print("🎤 请求麦克风权限...")
        return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                print(granted ? "✅ 麦克风权限已授予" : "❌ 麦克风权限被拒绝")
                continuation.resume(returning: granted)
            }
        }
    }
    
    private func requestSpeechRecognitionPermission() async -> Bool {
        print("🗣️ 请求语音识别权限...")
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                let granted = status == .authorized
                print(granted ? "✅ 语音识别权限已授予" : "❌ 语音识别权限被拒绝")
                continuation.resume(returning: granted)
            }
        }
    }
    
    // MARK: - AI 开场白
    private func generateAIGreeting() async {
        print("\n👋 ===== 生成 AI 开场白 =====")
        isProcessing = true
        
        do {
            let greetingPrompt = "请用简短的一句话打招呼并说明来意，不超过20个字"
            print("📤 发送提示词: \(greetingPrompt)")
            
            let (audioData, textResponse) = try await miniMaxService.sendTextMessage(greetingPrompt)
            
            print("📥 AI 回复: \(textResponse)")
            print("📊 音频大小: \(audioData.count) bytes")
            
            let message = ConversationMessage(text: textResponse, isUser: false)
            conversationMessages.append(message)
            
            print("🔧 配置音频会话为播放模式...")
            try await configureAudioSessionForPlayback()
            
            print("🔊 播放开场白音频...")
            try await miniMaxService.playAudio(audioData)
            print("✅ 开场白播放完成")
            
        } catch {
            errorMessage = "AI 初始化失败: \(error.localizedDescription)"
            print("❌ AI 开场白失败: \(error)")
        }
        
        isProcessing = false
        print("===========================\n")
    }
    
    // MARK: - 配置音频会话
    private func configureAudioSessionForPlayback() async throws {
        let audioSession = AVAudioSession.sharedInstance()
        
        print("🔧 配置音频会话 [播放模式]")
        
        try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        print("✅ 播放模式已激活")
    }
    
    private func configureAudioSessionForRecording() async throws {
        let audioSession = AVAudioSession.sharedInstance()
        
        print("🔧 配置音频会话 [录音模式]")
        
        try audioSession.setCategory(.record, mode: .measurement, options: [])
        try audioSession.setActive(true)
        
        print("✅ 录音模式已激活")
        print("📱 音频类别: \(audioSession.category)")
    }
    
    // MARK: - 开始自动录音（修复并发错误版）
    nonisolated private func startAutoRecording() async {
        print("\n🎤 ===== 开始自动录音 =====")
        
        do {
            try await configureAudioSessionForRecording()
            
            // 等待配置生效
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
            
            await MainActor.run {
                self.isRecording = true
                self.lastSoundTime = Date()
                self.hasSpokeOnce = false
                self.continuousSilenceCount = 0
                self.currentPower = -160.0
            }
            
            await MainActor.run {
                self.startSpeechRecognitionWithVolumeMonitoring()
                self.startSilenceDetection()
            }
            
            print("✅ 录音和识别已启动")
            print("🎯 等待用户说话...")
            print("===========================\n")
            
        } catch {
            await MainActor.run {
                self.errorMessage = "启动录音失败: \(error.localizedDescription)"
            }
            print("❌ 录音启动失败: \(error)")
        }
    }
    
    // MARK: - 语音识别 + 音量监测（不实时输出转写内容版）
    private func startSpeechRecognitionWithVolumeMonitoring() {
        print("🗣️ 启动语音识别引擎...")
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("⚠️ 语音识别不可用")
            return
        }
        
        // 停止之前的任务
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // 停止之前的音频引擎
        if audioEngine.isRunning {
            audioEngine.stop()
            if audioEngine.inputNode.numberOfInputs > 0 {
                audioEngine.inputNode.removeTap(onBus: 0)
            }
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("❌ 创建识别请求失败")
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation
        
        let inputNode = audioEngine.inputNode
        
        // ⭐ 显式创建有效的音频格式
        let recordingFormat: AVAudioFormat
        
        if let nodeFormat = inputNode.inputFormat(forBus: 0) as AVAudioFormat?,
           nodeFormat.sampleRate > 0 && nodeFormat.channelCount > 0 {
            recordingFormat = nodeFormat
            print("✅ 使用输入节点格式")
        } else if let nodeFormat = inputNode.outputFormat(forBus: 0) as AVAudioFormat?,
                  nodeFormat.sampleRate > 0 && nodeFormat.channelCount > 0 {
            recordingFormat = nodeFormat
            print("✅ 使用输出节点格式")
        } else if let standardFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16000.0,
            channels: 1,
            interleaved: false
        ) {
            recordingFormat = standardFormat
            print("✅ 使用标准格式（16kHz, 单声道）")
        } else {
            print("❌ 无法创建有效的音频格式")
            return
        }
        
        print("🔧 音频格式:")
        print("   采样率: \(recordingFormat.sampleRate) Hz")
        print("   声道数: \(recordingFormat.channelCount)")
        print("   格式ID: \(recordingFormat.commonFormat.rawValue)")
        
        guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
            print("❌ 音频格式无效")
            return
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self else { return }
            
            if let result = result {
                // 不再实时输出/更新 recognizedText，只用于静音检测逻辑
                let interimText = result.bestTranscription.formattedString
                if !interimText.isEmpty {
                    Task { @MainActor in
                        if !self.hasSpokeOnce { self.hasSpokeOnce = true }
                        self.lastSoundTime = Date()
                    }
                }
                
                // ⭐ 只在最终结果时更新 recognizedText（避免实时转写输出）
                if result.isFinal {
                    let finalText = result.bestTranscription.formattedString
                    Task { @MainActor in
                        self.recognizedText = finalText
                    }
                }
            }
            
            if let error = error {
                let nsError = error as NSError
                if nsError.domain != "kLSRErrorDomain" || nsError.code != 203 {
                    print("⚠️ 识别错误: \(error.localizedDescription)")
                }
            }
        }
        
        // ⭐ 安全地安装 tap
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            guard let self else { return }
            
            recognitionRequest.append(buffer)
            self.calculateAudioLevel(from: buffer)
        }
        
        print("✅ 音频 tap 已安装")
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            print("✅ 语音识别引擎已启动")
            print("🎤 开始监听...")
        } catch {
            print("❌ 语音识别引擎启动失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 从音频缓冲区计算音量
    private func calculateAudioLevel(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        
        let channelDataValue = channelData.pointee
        let channelDataValueArray = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride).map { channelDataValue[$0] }
        
        let rms = sqrt(channelDataValueArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
        let avgPower = 20 * log10(rms)
        
        Task { @MainActor in
            self.currentPower = avgPower
            
            let normalizedLevel = self.normalizeAudioLevel(avgPower)
            self.currentAudioLevel = normalizedLevel
            
            if avgPower > self.silenceThreshold {
                self.lastSoundTime = Date()
                self.continuousSilenceCount = 0
            } else {
                self.continuousSilenceCount += 1
            }
        }
    }
    
    // MARK: - 静音检测
    private func startSilenceDetection() {
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                guard self.hasSpokeOnce else { return }
                
                let silenceDuration = Date().timeIntervalSince(self.lastSoundTime)
                
                if silenceDuration >= self.silenceDuration && self.continuousSilenceCount >= 3 {
                    print("🔇 检测到静音 (\(String(format: "%.1f", silenceDuration))秒)")
                    await self.stopRecordingAndProcess()
                }
            }
        }
    }
    
    private func normalizeAudioLevel(_ decibels: Float) -> Float {
        let minDb: Float = -60.0
        let maxDb: Float = 0.0
        let clampedDb = max(minDb, min(maxDb, decibels))
        return (clampedDb - minDb) / (maxDb - minDb)
    }
    
    // MARK: - 停止录音并处理
    func stopRecordingAndProcess() async {
        print("\n⏹️ ===== 停止录音并处理 =====")
        
        audioLevelTimer?.invalidate()
        silenceTimer?.invalidate()
        
        audioEngine.stop()
        if audioEngine.inputNode.numberOfInputs > 0 {
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        // ⭐ 结束音频输入，让识别更快产出 final
        recognitionRequest?.endAudio()
        
        recognitionTask?.finish()
        recognitionTask = nil
        recognitionRequest = nil
        
        isRecording = false
        currentAudioLevel = 0.0
        
        guard !recognizedText.isEmpty else {
            print("⚠️ 未识别到文字，重新开始录音")
            recognizedText = ""
            hasSpokeOnce = false
            await startAutoRecording()
            return
        }
        
        let userText = recognizedText
        print("✅ 用户说话完成: \(userText)")
        
        isProcessing = true
        
        let userMessage = ConversationMessage(text: userText, isUser: true)
        conversationMessages.append(userMessage)
        recognizedText = ""
        hasSpokeOnce = false
        
        do {
            print("\n📤 发送给大模型...")
            let (audioData, textResponse) = try await miniMaxService.sendTextMessage(userText)
            
            print("📥 AI 回复: \(textResponse)")
            print("📊 音频大小: \(audioData.count) bytes")
            
            let message = ConversationMessage(text: textResponse, isUser: false)
            conversationMessages.append(message)
            
            print("\n🔧 切换到播放模式...")
            try await configureAudioSessionForPlayback()
            
            print("🔊 播放 AI 语音回复...")
            try await miniMaxService.playAudio(audioData)
            
            print("✅ AI 语音播放完成")
            print("✅ 一轮对话完成")
            
        } catch {
            errorMessage = "处理失败: \(error.localizedDescription)"
            print("❌ 处理失败: \(error)")
        }
        
        isProcessing = false
        print("===========================\n")
        
        print("🔄 准备下一轮录音...")
        await startAutoRecording()
    }
    
    // MARK: - 结束通话
    func endAICall() {
        print("\n📞 ===== 结束通话 =====")
        
        audioLevelTimer?.invalidate()
        silenceTimer?.invalidate()
        
        audioEngine.stop()
        if audioEngine.inputNode.numberOfInputs > 0 {
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        
        miniMaxService.stopAudio()
        miniMaxService.resetConversation()
        
        isAIEnabled = false
        conversationMessages = []
        isRecording = false
        currentAudioLevel = 0.0
        recognizedText = ""
        hasSpokeOnce = false
        continuousSilenceCount = 0
        
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            print("✅ 音频会话已清理")
        } catch {
            print("⚠️ 音频会话清理失败: \(error)")
        }
        
        print("✅ 通话已结束")
        print("===========================\n")
    }
}
