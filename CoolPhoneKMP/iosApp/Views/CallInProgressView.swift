import SwiftUI
import AVFoundation

struct CallInProgressView: View {
    let callerName: String
    let callerNumber: String
    @Binding var isPresented: Bool
    
    // AI 设置
    let scenario: CallScenario
    let customScenarioText: String
    
    @StateObject private var aiManager = AICallManager.shared
    @StateObject private var ringtoneManager = RingtoneManager.shared  // ⭐ 添加铃声管理器
    
    @State private var callDuration: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.0, blue: 0.15),
                    Color.black
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部通话信息
                VStack(spacing: 24) {
                    Spacer().frame(height: 60)
                    
                    // 通话时长
                    Text(formatDuration(callDuration))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    // 联系人头像
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.cyan, .blue, .purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: .cyan.opacity(0.5), radius: 30)
                        
                        Text(String(callerName.prefix(1)))
                            .font(.system(size: 50, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    // 联系人信息
                    VStack(spacing: 8) {
                        Text(callerName)
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(callerNumber)
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    /*
                    // AI 录音状态指示
                    if aiManager.isAIEnabled {
                        VStack(spacing: 12) {
                            // 录音状态
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(getStatusColor())
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(aiManager.isRecording ? 1.2 : 1.0)
                                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: aiManager.isRecording)
                                
                                Text(getStatusText())
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(getStatusColor())
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(getStatusColor().opacity(0.2))
                            )
                            
                            // 音量指示器
                            if aiManager.isRecording {
                                VoiceWaveformView(audioLevel: aiManager.currentAudioLevel)
                                    .frame(height: 40)
                                    .padding(.horizontal, 40)
                            }
                            
                            // 识别的文字
                            if !aiManager.recognizedText.isEmpty {
                                Text(aiManager.recognizedText)
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.1))
                                    )
                                    .padding(.horizontal, 30)
                            }
                        }
                    }
                }
                */
                Spacer()
                
                // AI 对话记录区域
                /*
                if aiManager.isAIEnabled && !aiManager.conversationMessages.isEmpty {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(aiManager.conversationMessages) { message in
                                    ConversationBubble(message: message)
                                        .id(message.id)
                                }
                                
                                // 加载指示
                                if aiManager.isProcessing {
                                    HStack {
                                        LoadingDots()
                                        Spacer()
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .onChange(of: aiManager.conversationMessages.count) { _, _ in
                                if let lastMessage = aiManager.conversationMessages.last {
                                    withAnimation {
                                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                    }
                                }
                            }
                        }
                        .frame(height: 200)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.05))
                                .padding(.horizontal, 16)
                        )
                    }                */
                }

                Spacer()
                
                // 底部操作按钮
                HStack(spacing: 50) {
                    // 静音按钮
                    CallActionButton(
                        icon: "mic.slash.fill",
                        label: "静音",
                        color: .white.opacity(0.3)
                    )
                    
                    // 挂断按钮
                    Button(action: {
                        endCall()
                    }) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 70, height: 70)
                                    .shadow(color: .red.opacity(0.5), radius: 15)
                                
                                Image(systemName: "phone.down.fill")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            Text("挂断")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    // 扬声器按钮
                    CallActionButton(
                        icon: "speaker.wave.3.fill",
                        label: "扬声器",
                        color: .white.opacity(0.3)
                    )
                }
                .padding(.bottom, 50)
            }
            
            // 错误提示
            if let errorMessage = aiManager.errorMessage {
                VStack {
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.2))
                            .overlay(
                                Capsule()
                                    .stroke(Color.orange, lineWidth: 1)
                            )
                    )
                    .padding(.bottom, 200)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            aiManager.errorMessage = nil
                        }
                    }
                }
            }
        }
        .onAppear {
            // ⭐⭐⭐ 立即停止铃声（最重要的修改！）
            print("📱 接听电话，停止铃声")
            ringtoneManager.stopRingtone()
            
            // 启动通话计时
            startCallTimer()
            
            // 初始化 AI 通话
            Task {
                await aiManager.initializeAICallWithAutoRecording(
                    scenario: scenario,
                    customText: customScenarioText
                )
            }
        }
        .onDisappear {
            timer?.invalidate()
            aiManager.endAICall()
            
            // ⭐ 确保铃声已停止
            ringtoneManager.stopRingtone()
        }
    }
    
    // MARK: - 获取状态颜色
    private func getStatusColor() -> Color {
        if aiManager.isProcessing {
            return .orange
        } else if aiManager.isRecording {
            return .red
        } else {
            return .green
        }
    }
    
    // MARK: - 获取状态文字
    private func getStatusText() -> String {
        if aiManager.isProcessing {
            return "AI 思考中..."
        } else if aiManager.isRecording {
            return "正在倾听..."
        } else {
            return "等待回复..."
        }
    }
    
    // MARK: - 格式化通话时长
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - 开始计时
    private func startCallTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            callDuration += 1
        }
    }
    
    // MARK: - 结束通话
    private func endCall() {
        timer?.invalidate()
        aiManager.endAICall()
        
        // ⭐ 确保铃声已停止
        ringtoneManager.stopRingtone()
        
        isPresented = false
    }
}

// MARK: - 音量波形视图
struct VoiceWaveformView: View {
    let audioLevel: Float
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<20) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.red, .orange]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 3)
                    .frame(height: getBarHeight(for: index))
                    .animation(.easeInOut(duration: 0.1), value: audioLevel)
            }
        }
    }
    
    private func getBarHeight(for index: Int) -> CGFloat {
        let baseHeight: CGFloat = 4
        let maxHeight: CGFloat = 40
        
        let normalizedLevel = CGFloat(audioLevel)
        let randomFactor = CGFloat.random(in: 0.7...1.0)
        
        return baseHeight + (maxHeight - baseHeight) * normalizedLevel * randomFactor
    }
}

// MARK: - 通话操作按钮
struct CallActionButton: View {
    let icon: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

// MARK: - 对话气泡
struct ConversationBubble: View {
    let message: ConversationMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(message.isUser ? Color.cyan.opacity(0.3) : Color.white.opacity(0.15))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(message.isUser ? Color.cyan.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
                
                Text(message.timestamp, style: .time)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal, 8)
            }
            
            if !message.isUser {
                Spacer()
            }
        }
    }
}

// MARK: - 加载动画
struct LoadingDots: View {
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 8, height: 8)
                    .scaleEffect(animating ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.15))
        )
        .onAppear {
            animating = true
        }
    }
}
