import SwiftUI

struct LiquidMetalSplash: View {
    @Binding var isActive: Bool
    @State private var phase: CGFloat = 0
    @State private var morphProgress: CGFloat = 0
    @State private var rippleScale: CGFloat = 0
    @State private var contentOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // 深色背景
            Color.black.ignoresSafeArea()
            
            // 波纹背景
            ForEach(0..<5) { index in
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.8),
                                Color.cyan.opacity(0.4),
                                Color.clear
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 300, height: 300)
                    .scaleEffect(rippleScale)
                    .opacity(1 - rippleScale)
                    .animation(
                        .easeOut(duration: 3)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.4),
                        value: rippleScale
                    )
            }
            
            VStack(spacing: 50) {
                Spacer()
                
                // 液态金属图标
                ZStack {
                    // 发光底层
                    LiquidMetalShape(phase: phase)
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.cyan.opacity(0.8),
                                    Color.blue.opacity(0.6),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 50,
                                endRadius: 150
                            )
                        )
                        .frame(width: 200, height: 200)
                        .blur(radius: 20)
                    
                    // 液态金属层
                    LiquidMetalShape(phase: phase)
                        .fill(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    .blue,
                                    .cyan,
                                    .white,
                                    .cyan,
                                    .blue
                                ]),
                                center: .center,
                                angle: .degrees(phase * 360)
                            )
                        )
                        .frame(width: 180, height: 180)
                        .overlay(
                            LiquidMetalShape(phase: phase)
                                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                        )
                        .shadow(color: .cyan, radius: 30, x: 0, y: 0)
                    
                    // 电话图标
                    Image(systemName: "phone.fill")
                        .font(.system(size: 70, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .white,
                                    .cyan.opacity(0.8)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .white, radius: 10)
                }
                .opacity(contentOpacity)
                
                // 标题
                VStack(spacing: 20) {
                    HStack(spacing: 0) {
                        ForEach(Array("虚拟来电".enumerated()), id: \.offset) { index, char in
                            Text(String(char))
                                .font(.system(size: 45, weight: .heavy, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            .cyan,
                                            .blue,
                                            .purple
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .cyan, radius: 15)
                                .offset(y: contentOpacity * 20 * sin(Double(index) * 0.5 + Double(phase) * 2))
                        }
                    }
                    
                    // 扫描线效果
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .clear,
                                    .cyan,
                                    .clear
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 250, height: 2)
                        .opacity(contentOpacity)
                    
                    Text("LIQUID METAL DESIGN")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan.opacity(0.8))
                        .tracking(5)
                        .opacity(contentOpacity)
                }
                
                Spacer()
                
                // 进度指示器
                HStack(spacing: 12) {
                    ForEach(0..<3) { index in
                        Capsule()
                            .fill(Color.cyan)
                            .frame(width: index == Int(phase * 3) % 3 ? 30 : 8, height: 8)
                            .shadow(color: .cyan, radius: 5)
                    }
                }
                .opacity(contentOpacity)
                .padding(.bottom, 80)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Animations
    private func startAnimations() {
        // 相位动画（液态效果）
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            phase = 1.0
        }
        
        // 波纹扩散
        withAnimation(.easeOut(duration: 1).delay(0.5)) {
            rippleScale = 3.0
        }
        
        // 内容淡入
        withAnimation(.easeOut(duration: 1.5).delay(0.3)) {
            contentOpacity = 1.0
        }
        
        // 形变进度
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            morphProgress = 1.0
        }
        
        // 3.5秒后关闭
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                isActive = false
            }
        }
    }
}

// MARK: - 液态金属形状
struct LiquidMetalShape: Shape {
    var phase: CGFloat
    
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let centerX = width / 2
        let centerY = height / 2
        
        // 创建液态边缘
        path.move(to: CGPoint(x: centerX, y: 0))
        
        for angle in stride(from: 0, through: 360, by: 5) {
            let radians = Double(angle) * Double.pi / 180
            let wave = sin(radians * 5 + phase * 2 * .pi) * 10
            let radius = min(width, height) / 2 + wave
            
            let x = centerX + cos(radians) * radius
            let y = centerY + sin(radians) * radius
            
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.closeSubpath()
        return path
    }
}

#Preview {
    LiquidMetalSplash(isActive: .constant(true))
}
