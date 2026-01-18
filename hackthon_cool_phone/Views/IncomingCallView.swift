import SwiftUI
import AVFoundation

struct IncomingCallView: View {
    // MARK: - 属性
    let callerName: String
    let callerNumber: String
    let scenario: CallScenario
    let customScenarioText: String
    
    @Binding var isPresented: Bool
    
    @StateObject private var ringtoneManager = RingtoneManager.shared
    @State private var isCallAccepted = false
    @State private var pulseAnimation = false
    @State private var slideOffset: CGFloat = 0
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.0, blue: 0.2),
                    Color.black
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // 来电提示
                Text("来电")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 60)
                
                Spacer().frame(height: 40)
                
                // 联系人头像（带脉冲动画）
                ZStack {
                    // 外圈脉冲
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(Color.cyan.opacity(0.3), lineWidth: 2)
                            .frame(width: 140 + CGFloat(index * 30), height: 140 + CGFloat(index * 30))
                            .scaleEffect(pulseAnimation ? 1.3 : 1.0)
                            .opacity(pulseAnimation ? 0.0 : 0.8)
                            .animation(
                                .easeOut(duration: 1.5)
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(index) * 0.3),
                                value: pulseAnimation
                            )
                    }
                    
                    // 头像
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.cyan, .blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .shadow(color: .cyan.opacity(0.6), radius: 30)
                    
                    Text(String(callerName.prefix(1)))
                        .font(.system(size: 60, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Spacer().frame(height: 40)
                
                // 联系人信息
                VStack(spacing: 12) {
                    Text(callerName)
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(callerNumber)
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.7))
                    
                    // 场景标签
                    HStack(spacing: 8) {
                        Image(systemName: getScenarioIcon())
                            .font(.system(size: 14))
                        
                        Text(scenario.rawValue)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.cyan.opacity(0.2))
                            .overlay(
                                Capsule()
                                    .stroke(Color.cyan.opacity(0.4), lineWidth: 1)
                            )
                    )
                }
                
                Spacer()
                
                // AI 提示
                /*
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                    
                    Text("AI 助手已就绪")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                )
                */
                Spacer().frame(height: 40)
                
                // 接听/拒绝按钮
                HStack(spacing: 80) {
                    // 拒绝按钮
                    Button(action: {
                        rejectCall()
                    }) {
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 75, height: 75)
                                    .shadow(color: .red.opacity(0.5), radius: 20)
                                
                                Image(systemName: "phone.down.fill")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            Text("拒绝")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .buttonStyle(CallButtonStyle())
                    
                    // 接听按钮
                    Button(action: {
                        acceptCall()
                    }) {
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 75, height: 75)
                                    .shadow(color: .green.opacity(0.5), radius: 20)
                                
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            Text("接听")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .buttonStyle(CallButtonStyle())
                }
                .padding(.bottom, 80)
                
                // 滑动接听提示（可选）
                SlideToAnswerHint()
                    .padding(.bottom, 40)
                    .opacity(0.6)
            }
            
            // 通话界面（全屏覆盖）
            if isCallAccepted {
                CallInProgressView(
                    callerName: callerName,
                    callerNumber: callerNumber,
                    isPresented: $isPresented,
                    scenario: scenario,
                    customScenarioText: customScenarioText
                )
                .transition(.move(edge: .bottom))
                .zIndex(1)
            }
        }
        .onAppear {
            print("\n━━━━━━━━━━━━━━━━━━━━━━━━")
            print("📱 来电界面 onAppear 被调用")
            print("📱 调用时间: \(Date())")
            
            // 测试 RingtoneManager 是否可用
            print("📱 RingtoneManager.shared: \(RingtoneManager.shared)")
            print("📱 当前播放状态: \(ringtoneManager.isPlaying)")
            
            // 尝试播放铃声
            print("📱 准备播放铃声...")
            ringtoneManager.playRingtone()
            
            // 检查播放状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("📱 播放状态检查: \(self.ringtoneManager.isPlaying)")
            }
            
            // 启动动画
            pulseAnimation = true
            
            print("━━━━━━━━━━━━━━━━━━━━━━━━\n")
        }
        .onDisappear {
            // ⭐ 确保铃声停止
            print("📱 来电界面消失，停止铃声")
            ringtoneManager.stopRingtone()
        }
    }
    
    // MARK: - 接听电话
    private func acceptCall() {
        print("📱 接听电话")
        
        // ⭐ 立即停止铃声
        ringtoneManager.stopRingtone()
        
        // 触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // 显示通话界面
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isCallAccepted = true
        }
    }
    
    // MARK: - 拒绝电话
    private func rejectCall() {
        print("📱 拒绝电话")
        
        // ⭐ 停止铃声
        ringtoneManager.stopRingtone()
        
        // 触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // 关闭界面
        withAnimation {
            isPresented = false
        }
    }
    
    // MARK: - 获取场景图标
    private func getScenarioIcon() -> String {
        switch scenario {
        case .urgent: return "exclamationmark.triangle.fill"
        case .work: return "briefcase.fill"
        case .family: return "heart.fill"
        case .health: return "cross.case.fill"
        case .delivery: return "shippingbox.fill"
        case .meeting: return "calendar"
        case .emergency: return "alarm.fill"
        case .custom: return "star.fill"
        }
    }
}

// MARK: - 按钮样式
struct CallButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - 滑动接听提示
struct SlideToAnswerHint: View {
    @State private var animateArrow = false
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.left")
                .font(.system(size: 14))
                .offset(x: animateArrow ? -5 : 5)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animateArrow)
            
            Text("向左拒绝")
                .font(.system(size: 13))
            
            Spacer()
            
            Text("向右接听")
                .font(.system(size: 13))
            
            Image(systemName: "arrow.right")
                .font(.system(size: 14))
                .offset(x: animateArrow ? 5 : -5)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animateArrow)
        }
        .foregroundColor(.white.opacity(0.4))
        .padding(.horizontal, 60)
        .onAppear {
            animateArrow = true
        }
    }
}

// MARK: - 预览
#Preview {
    IncomingCallView(
        callerName: "张三",
        callerNumber: "138****5678",
        scenario: .urgent,
        customScenarioText: "",
        isPresented: .constant(true)
    )
}
