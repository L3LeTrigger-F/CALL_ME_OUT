import Foundation
import AVFoundation
import Combine

// MARK: - MiniMax 语音服务（支持多轮对话）
class MiniMaxVoiceService: ObservableObject {
    static let shared = MiniMaxVoiceService()
    
    @Published var isProcessing = false
    @Published var currentResponseText = ""
    @Published var conversationCount = 0
    @Published var isConversationActive = false
    
    // API 配置
    private let groupId = "2011642032728056634"
    private let apiKey = "sk-api-bx_95QbykqrjucyztWiWz9dRPQrn8HsTe0_8onfwsbzZZvKmXnGNdCuvtm9fIeNxQbS8cmEdqBkNGy-peIp4Kj0h2hhIlUTiqgZXL08F-yKJDWbIup5tPuU"
    
    // 对话管理
    private var conversationHistory: [[String: String]] = []
    private var currentScenario: CallScenario = .urgent
    private var customScenarioText: String = ""
    private var systemPrompt: String = ""
    
    private var audioPlayer: AVAudioPlayer?
    
    private init() {
        print("⚙️ MiniMax Service 初始化")
    }
    
    // MARK: - 设置场景（只在开始时调用一次）
    func setupScenario(_ scenario: CallScenario, customText: String = "") {
        self.currentScenario = scenario
        self.customScenarioText = customText
        
        systemPrompt = generateSystemPrompt(for: scenario, customText: customText)
        
        if !isConversationActive {
            conversationHistory = [
                ["role": "system", "content": systemPrompt]
            ]
            conversationCount = 0
            isConversationActive = true
            print("✅ 场景设置完成: \(scenario.rawValue)")
            print("📝 初始化对话历史")
        } else {
            print("⚠️ 对话已激活，不重置历史")
        }
    }
    
    // MARK: - 生成系统提示词
    private func generateSystemPrompt(for scenario: CallScenario, customText: String) -> String {
        let basePrompt = """
        你是一个专业的电话对话AI助手。请根据以下场景进行对话：
        
        场景：\(scenario.rawValue)
        """
        
        let scenarioPrompt: String
        switch scenario {
        case .urgent:
            scenarioPrompt = "你正在紧急联系对方，语气要紧张但不失礼貌。随着对话进展，可以逐渐说明紧急情况的具体内容。"
        case .work:
            scenarioPrompt = "你是对方的老板，正在安排重要工作任务，语气要专业且有权威。可以根据对方的回复进一步说明任务细节。开头统一是你好。1. 不要在任何内容中使用具体姓名、昵称或身份指代（如“小王”“你们新人”等）2. 不要假设用户的性别、年龄、职级或入职时间。3. 领导对用户的称呼必须保持模糊与通用（如“你”“这边”“我们”）"
        case .family:
            scenarioPrompt = "你是对方的家人，正在谈论家庭事务，语气要温暖关切。可以询问对方的近况并分享家里的消息。"
        case .health:
            scenarioPrompt = "你是医生，正在通知检查结果或健康问题，语气要专业且富有同情心。根据对方的疑问提供详细解释。"
        case .delivery:
            scenarioPrompt = "你是快递员，正在通知快递到达，语气要热情友好。可以说明快递的位置和取件方式。"
        case .meeting:
            scenarioPrompt = "你正在通知对方会议信息，语气要正式专业。可以说明会议的时间、地点和议题。"
        case .emergency:
            scenarioPrompt = "这是紧急情况，语气要急促且严肃。需要对方立即采取行动。"
        case .custom:
            scenarioPrompt = customText.isEmpty ? "请自然对话。" : customText
        }
        
        let guidelines = """
        
        对话指南：
        1. 每次回复控制在20-30字以内，保持简洁
        2. 使用自然的口语表达
        3. 根据用户的回复做出合理反应
        4. 保持角色一致性
        5. 记住之前的对话内容，保持上下文连贯
        6. 如果用户问"你是谁"或"什么事"，要结合之前的对话回答
        
        \(scenarioPrompt)
        """
        
        return basePrompt + guidelines
    }
    
    // MARK: - 发送文字消息（保持对话历史）
    func sendTextMessage(_ text: String) async throws -> (audioData: Data, textResponse: String) {
        print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📤 第 \(conversationCount + 1) 轮对话")
        // ❌ 不再打印用户文本内容
        
        guard !apiKey.contains("sk-") || apiKey.count > 20 else {
            throw MiniMaxError.apiError(message: "请先在代码中设置正确的 API Key")
        }
        
        if !isConversationActive {
            print("⚠️ 对话未激活，自动初始化...")
            setupScenario(currentScenario, customText: customScenarioText)
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        conversationHistory.append([
            "role": "user",
            "content": text
        ])
        
        print("📚 当前对话历史条数: \(conversationHistory.count)")
        // ❌ 不再打印对话历史内容
        
        guard let url = URL(string: "https://api.minimax.chat/v1/text/chatcompletion_v2?GroupId=\(groupId)") else {
            throw MiniMaxError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        let requestBody: [String: Any] = [
            "model": "abab6.5s-chat",
            "messages": conversationHistory,
            "temperature": 0.7,
            "max_tokens": 100,
            "top_p": 0.95
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("🔄 调用 MiniMax API...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MiniMaxError.invalidResponse
        }
        
        print("📥 状态码: \(httpResponse.statusCode)")
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ 响应内容: \(responseString.prefix(200))")
            }
            throw MiniMaxError.invalidResponse
        }
        
        if let baseResp = json["base_resp"] as? [String: Any],
           let statusCode = baseResp["status_code"] as? Int,
           statusCode != 0 {
            let statusMsg = baseResp["status_msg"] as? String ?? "未知错误"
            print("❌ API 错误: \(statusMsg)")
            throw MiniMaxError.apiError(message: statusMsg)
        }
        
        if httpResponse.statusCode != 200 {
            throw MiniMaxError.requestFailed(statusCode: httpResponse.statusCode)
        }
        
        guard let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let textResponse = message["content"] as? String else {
            print("❌ 无法解析回复内容")
            throw MiniMaxError.invalidResponse
        }
        
        // ❌ 不再打印 AI 文本内容
        
        conversationHistory.append([
            "role": "assistant",
            "content": textResponse
        ])
        
        conversationCount += 1
        print("✅ 第 \(conversationCount) 轮对话完成")
        print("📚 对话历史已更新，当前条数: \(conversationHistory.count)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        
        let audioData = try await convertTextToSpeech(textResponse)
        
        await MainActor.run {
            currentResponseText = textResponse
        }
        
        return (audioData: audioData, textResponse: textResponse)
    }
    
    // MARK: - 文字转语音
    private func convertTextToSpeech(_ text: String) async throws -> Data {
        print("🔊 开始语音合成...")
        // ❌ 不再打印文字内容
        
        guard let url = URL(string: "https://api.minimax.chat/v1/text_to_speech?GroupId=\(groupId)") else {
            throw MiniMaxError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        let voiceId = selectVoiceForScenario()
        print("🎤 使用音色: \(voiceId)")
        
        let requestBody: [String: Any] = [
            "voice_id": voiceId,
            "text": text,
            "model": "speech-01",
            "speed": 1.0,
            "vol": 1.0,
            "pitch": 0,
            "timber_weights": [
                [
                    "voice_id": voiceId,
                    "weight": 1
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("🔄 调用 TTS API...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MiniMaxError.invalidResponse
        }
        
        print("📥 TTS 状态码: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ TTS 错误响应: \(errorString.prefix(200))")
            }
            throw MiniMaxError.requestFailed(statusCode: httpResponse.statusCode)
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let baseResp = json["base_resp"] as? [String: Any],
               let statusCode = baseResp["status_code"] as? Int,
               statusCode != 0 {
                let statusMsg = baseResp["status_msg"] as? String ?? "未知错误"
                print("❌ TTS API 错误: \(statusMsg)")
                throw MiniMaxError.apiError(message: statusMsg)
            }
            
            if let extra_info = json["extra_info"] as? [String: Any],
               let audioBase64 = extra_info["audio_file"] as? String,
               let audioData = Data(base64Encoded: audioBase64) {
                print("✅ TTS 成功（base64 格式），大小: \(audioData.count) bytes")
                return audioData
            }
        }
        
        print("✅ TTS 成功（MP3 格式），大小: \(data.count) bytes")
        
        if data.count < 1000 {
            print("⚠️ 警告：音频数据太小，可能无效")
        }
        
        return data
    }
    
    private func selectVoiceForScenario() -> String {
        switch currentScenario {
        case .work: return "male-qn-qingse"
        case .family: return "female-shaonv"
        case .health: return "male-qn-jingying"
        case .delivery: return "male-qn-qingse"
        case .meeting: return "female-yujie"
        case .emergency: return "male-qn-jingying"
        default: return "female-tianmei"
        }
    }
    
    // MARK: - 播放音频（已优化）
    func playAudio(_ audioData: Data) async throws {
        print("\n🔊 ===== 开始播放音频 =====")
        print("📊 音频数据大小: \(audioData.count) bytes")
        
        if audioData.count < 100 {
            print("❌ 音频数据太小，无法播放")
            throw MiniMaxError.invalidAudio
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let audioSession = AVAudioSession.sharedInstance()
                print("🔧 配置音频会话...")
                
                try audioSession.setCategory(
                    .playback,
                    mode: .default,
                    options: [.duckOthers]
                )
                print("✅ 音频类别设置为 .playback")
                
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                print("✅ 音频会话已激活")
                
                print("📱 当前音频类别: \(audioSession.category)")
                print("📱 当前音频模式: \(audioSession.mode)")
                print("📱 其他音频是否播放中: \(audioSession.isOtherAudioPlaying)")
                
                print("🎵 创建音频播放器...")
                audioPlayer = try AVAudioPlayer(data: audioData)
                
                guard let player = audioPlayer else {
                    print("❌ 创建播放器失败")
                    continuation.resume(throwing: MiniMaxError.invalidAudio)
                    return
                }
                
                player.prepareToPlay()
                player.volume = 50.0
                
                print("🎵 播放器配置:")
                print("   - 时长: \(player.duration) 秒")
                print("   - 音量: \(player.volume)")
                print("   - 声道数: \(player.numberOfChannels)")
                print("   - 当前时间: \(player.currentTime)")
                
                let playSuccess = player.play()
                
                if playSuccess {
                    print("✅ 音频开始播放")
                    print("🔊 播放状态: \(player.isPlaying ? "播放中" : "未播放")")
                    
                    let playDuration = player.duration + 0.5
                    print("⏱️ 将在 \(playDuration) 秒后完成")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + playDuration) {
                        print("✅ 音频播放完成")
                        print("===========================\n")
                        continuation.resume()
                    }
                } else {
                    print("❌ 播放失败：player.play() 返回 false")
                    continuation.resume(throwing: MiniMaxError.invalidAudio)
                }
                
            } catch let error as NSError {
                print("❌ 播放音频失败")
                print("   错误域: \(error.domain)")
                print("   错误代码: \(error.code)")
                print("   错误描述: \(error.localizedDescription)")
                
                if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError {
                    print("   底层错误: \(underlyingError.localizedDescription)")
                }
                
                continuation.resume(throwing: error)
            }
        }
    }
    
    func stopAudio() {
        if let player = audioPlayer, player.isPlaying {
            print("⏹️ 停止音频播放")
            player.stop()
        }
        audioPlayer = nil
    }
    
    // MARK: - 重置对话
    func resetConversation() {
        conversationHistory = []
        if !systemPrompt.isEmpty {
            conversationHistory.append([
                "role": "system",
                "content": systemPrompt
            ])
        }
        currentResponseText = ""
        conversationCount = 0
        isConversationActive = false
        print("🔄 对话已重置")
    }
    
    // MARK: - 查看对话历史（调试用）
    func printConversationHistory() {
        print("\n📚 ===== 对话历史 =====")
        print("对话轮数: \(conversationCount)")
        print("历史条数: \(conversationHistory.count)")
        for (index, msg) in conversationHistory.enumerated() {
            let role = msg["role"] ?? "unknown"
            // ❌ 不再打印 content
            print("[\(index)] role: \(role)")
        }
        print("========================\n")
    }
}

// MARK: - 错误类型
enum MiniMaxError: Error, LocalizedError {
    case invalidURL
    case invalidRequest
    case invalidResponse
    case invalidAudio
    case requestFailed(statusCode: Int)
    case networkError(Error)
    case apiError(message: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 API 地址"
        case .invalidRequest:
            return "请求数据格式错误"
        case .invalidResponse:
            return "服务器响应格式错误"
        case .invalidAudio:
            return "音频数据无效"
        case .requestFailed(let code):
            return "请求失败，状态码: \(code)"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .apiError(let message):
            return "API 错误: \(message)"
        }
    }
}
