import SwiftUI

// MARK: - 动态背景
struct AnimatedBackground: View {
    @State private var moveCircles = false
    
    var body: some View {
        ZStack {
            // 基础深色背景
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.0, blue: 0.15),
                    Color(red: 0.1, green: 0.05, blue: 0.2),
                    Color.black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 动态光圈
            ForEach(0..<3) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.cyan.opacity(0.15),
                                Color.blue.opacity(0.1),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .blur(radius: 30)
                    .offset(
                        x: moveCircles ? CGFloat.random(in: -100...100) : CGFloat.random(in: -50...50),
                        y: moveCircles ? CGFloat.random(in: -100...100) : CGFloat.random(in: -50...50)
                    )
                    .animation(
                        .easeInOut(duration: Double.random(in: 8...12))
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 2),
                        value: moveCircles
                    )
            }
            
            // 星空粒子
            GeometryReader { geometry in
                ForEach(0..<50, id: \.self) { _ in
                    Circle()
                        .fill(Color.white.opacity(Double.random(in: 0.1...0.4)))
                        .frame(width: CGFloat.random(in: 1...3), height: CGFloat.random(in: 1...3))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                }
            }
        }
        .onAppear {
            moveCircles = true
        }
    }
}

// MARK: - 炫酷 App 介绍 Bar
struct CoolAppIntroductionBar: View {
    @Binding var rotationAngle: Double
    @Binding var pulseScale: CGFloat
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // 超酷应用图标
                ZStack {
                    // 外层光晕
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.cyan.opacity(0.4),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 40
                            )
                        )
                        .frame(width: 80, height: 80)
                        .blur(radius: 10)
                        .scaleEffect(pulseScale)
                    
                    // 旋转环
                    Circle()
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    .cyan,
                                    .blue,
                                    .purple,
                                    .cyan
                                ]),
                                center: .center
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 65, height: 65)
                        .rotationEffect(.degrees(rotationAngle))
                    
                    // 主图标
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.cyan,
                                    Color.blue,
                                    Color.purple
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 55, height: 55)
                        .shadow(color: .cyan, radius: 20, x: 0, y: 0)
                    
                    Image(systemName: "phone.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    // 标题 - 渐变文字
                    Text("智逃")
                        .font(.system(size: 24, weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .cyan,
                                    .blue,
                                    .purple
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .cyan.opacity(0.5), radius: 10, x: 0, y: 0)
                    
                    Text("CALL ME OUT")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan.opacity(0.7))
                        .tracking(3)
                }
                
                Spacer()
            }
            
            // 介绍文字 - 霓虹边框
            Text("快速生成虚拟来电，帮助你优雅地脱离尴尬场景。支持音量键快捷触发，自定义来电信息，让你的脱身更加自然。")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .background(
            ZStack {
                // 玻璃拟态背景
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.cyan.opacity(0.5),
                                        Color.blue.opacity(0.3),
                                        Color.purple.opacity(0.5)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .blur(radius: 0.5)
            }
        )
        .shadow(color: .cyan.opacity(0.3), radius: 20, x: 0, y: 10)
    }
}

// MARK: - 霓虹功能卡片
struct NeonFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let primaryColor: Color
    let secondaryColor: Color
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var shimmerOffset: CGFloat = -200
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                // 3D 图标
                ZStack {
                    // 背景光晕
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    primaryColor.opacity(0.4),
                                    primaryColor.opacity(0.2),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 50
                            )
                        )
                        .frame(width: 80, height: 80)
                        .blur(radius: 10)
                    
                    // 主图标背景
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    primaryColor,
                                    secondaryColor
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 65, height: 65)
                        .shadow(color: primaryColor.opacity(0.8), radius: 15, x: 0, y: 5)
                    
                    // 图标
                    Image(systemName: icon)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .white.opacity(0.5), radius: 5)
                }
                
                // 文字内容
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                }
                
                Spacer()
                
                // 箭头指示器
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(primaryColor)
                }
            }
            .padding(20)
            .background(
                ZStack {
                    // 玻璃拟态背景
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.05))
                    
                    // 霓虹边框
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    primaryColor.opacity(0.6),
                                    secondaryColor.opacity(0.3),
                                    primaryColor.opacity(0.6)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                    
                    // 闪光效果
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.clear,
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: shimmerOffset)
                        .mask(RoundedRectangle(cornerRadius: 20))
                }
            )
            .shadow(color: primaryColor.opacity(isPressed ? 0.6 : 0.3), radius: isPressed ? 25 : 15, x: 0, y: isPressed ? 10 : 5)
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
        .onAppear {
            startShimmerAnimation()
        }
    }
    
    private func startShimmerAnimation() {
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            shimmerOffset = 400
        }
    }
}

// MARK: - 玻璃拟态提示卡片
struct GlassmorphicTipsCard: View {
    @Binding var isVolumeMonitoringEnabled: Bool
    @State private var glowIntensity: Double = 0.3
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                // 发光图标
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.orange.opacity(0.6),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 20
                            )
                        )
                        .frame(width: 40, height: 40)
                        .blur(radius: 5)
                        .opacity(glowIntensity)
                    
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .yellow,
                                    .orange
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .font(.system(size: 20))
                        .shadow(color: .orange, radius: 10)
                }
                
                Text("快捷提示")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 14) {
                Toggle(isOn: $isVolumeMonitoringEnabled) {
                    HStack(spacing: 10) {
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [.cyan, .blue]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .font(.system(size: 16))
                        Text("截图键触发来电")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .cyan))
                
                if isVolumeMonitoringEnabled {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.cyan.opacity(0.6))
                            .font(.system(size: 13))
                        Text("截图键即可触发虚拟来电")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.leading, 8)
                }
            }
        }
        .padding(20)
        .background(
            ZStack {
                // 玻璃背景
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
                
                // 渐变边框
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.orange.opacity(0.5),
                                Color.yellow.opacity(0.3),
                                Color.orange.opacity(0.5)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        )
        .shadow(color: .orange.opacity(0.3), radius: 15, x: 0, y: 5)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowIntensity = 0.8
            }
        }
    }
}

// MARK: - 炫酷 Toast
struct CoolToast: View {
    let message: String
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack {
            HStack(spacing: 12) {
                // 动态图标
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.green.opacity(0.6),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 20
                            )
                        )
                        .frame(width: 40, height: 40)
                        .blur(radius: 5)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.green, .mint]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .font(.system(size: 22))
                        .shadow(color: .green, radius: 10)
                }
                
                Text(message)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                    
                    Capsule()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.green.opacity(0.6),
                                    Color.mint.opacity(0.4),
                                    Color.green.opacity(0.6)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1.5
                        )
                }
            )
            .shadow(color: .green.opacity(0.4), radius: 20, x: 0, y: 10)
        }
        .padding(.top, 60)
        .transition(.move(edge: .top).combined(with: .opacity))
        .zIndex(1)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    isShowing = false
                }
            }
        }
    }
}

// MARK: - 霓虹按钮
struct NeonButton: View {
    let icon: String
    let title: String
    let primaryColor: Color
    let secondaryColor: Color
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var glowIntensity: Double = 0.5
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
                Text(title)
                    .font(.system(size: 18, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                ZStack {
                    // 发光背景
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    primaryColor.opacity(0.3),
                                    secondaryColor.opacity(0.2)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    // 霓虹边框
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    primaryColor,
                                    secondaryColor,
                                    primaryColor
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                }
            )
            .foregroundColor(.white)
            .shadow(color: primaryColor.opacity(glowIntensity), radius: isPressed ? 30 : 20, x: 0, y: isPressed ? 8 : 5)
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowIntensity = 0.8
            }
        }
    }
}

// MARK: - 提示行组件（带颜色）
struct TipRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 14))
                .frame(width: 20)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}
