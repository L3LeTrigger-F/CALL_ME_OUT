//
//  ParticleExplosionSplash.swift.swift
//  hackthon_cool_phone
//
//  Created by leslie liu on 2026/1/17.
//

import SwiftUI

struct ParticleExplosionSplash: View {
    @Binding var isActive: Bool
    @State private var particles: [Particle] = []
    @State private var phoneScale: CGFloat = 0.1
    @State private var phoneRotation3D: Double = 0
    @State private var glowIntensity: Double = 0
    @State private var textScale: CGFloat = 0
    @State private var showLightning = false
    
    var body: some View {
        ZStack {
            // 深空背景
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
            
            // 星空背景
            ForEach(0..<50, id: \.self) { _ in
                Circle()
                    .fill(Color.white)
                    .frame(width: CGFloat.random(in: 1...3), height: CGFloat.random(in: 1...3))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .opacity(Double.random(in: 0.3...1.0))
            }
            
            // 粒子效果
            ForEach(particles) { particle in
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                particle.color,
                                particle.color.opacity(0)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 15
                        )
                    )
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }
            
            VStack(spacing: 40) {
                Spacer()
                
                // 主图标 - 3D旋转效果
                ZStack {
                    // 外层光环
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.cyan.opacity(0.8),
                                        Color.purple.opacity(0.6),
                                        Color.pink.opacity(0.4)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 180 + CGFloat(index * 30), height: 180 + CGFloat(index * 30))
                            .blur(radius: 3)
                            .rotationEffect(.degrees(phoneRotation3D * Double(index + 1)))
                            .opacity(glowIntensity)
                    }
                    
                    // 发光效果
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.cyan.opacity(0.6),
                                    Color.purple.opacity(0.3),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .blur(radius: 20)
                        .scaleEffect(phoneScale * 1.5)
                    
                    // 主图标背景
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.cyan,
                                    Color.purple,
                                    Color.pink
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 160, height: 160)
                        .shadow(color: .cyan.opacity(0.8), radius: 30, x: 0, y: 0)
                        .scaleEffect(phoneScale)
                        .rotation3DEffect(
                            .degrees(phoneRotation3D),
                            axis: (x: 1, y: 1, z: 0)
                        )
                    
                    // 电话图标
                    Image(systemName: "phone.fill")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.white, .white.opacity(0.8)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .white.opacity(0.8), radius: 10)
                        .scaleEffect(phoneScale)
                        .rotation3DEffect(
                            .degrees(phoneRotation3D),
                            axis: (x: 1, y: 1, z: 0)
                        )
                }
                
                // 标题 - 霓虹灯效果
                VStack(spacing: 16) {
                    Text("智逃")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .cyan,
                                    .purple,
                                    .pink
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .cyan, radius: 20, x: 0, y: 0)
                        .shadow(color: .purple, radius: 20, x: 0, y: 0)
                        .scaleEffect(textScale)
                    
                    HStack(spacing: 8) {
                        ForEach(Array("Call Me Out".enumerated()), id: \.offset) { index, char in
                            Text(String(char))
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyan)
                                .opacity(textScale)
                                .animation(.easeOut.delay(Double(index) * 0.05), value: textScale)
                        }
                    }
                    .tracking(4)
                }
                
                Spacer()
                
                // 加载进度
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 3)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: glowIntensity)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.cyan, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        .rotationEffect(.degrees(phoneRotation3D))
                }
                .padding(.bottom, 80)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Particle Model
    struct Particle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var size: CGFloat
        var color: Color
        var opacity: Double
    }
    
    // MARK: - Animations
    private func startAnimations() {
        // 图标3D旋转和缩放
        withAnimation(.spring(response: 1.5, dampingFraction: 0.6)) {
            phoneScale = 1.0
        }
        
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: false)) {
            phoneRotation3D = 360
        }
        
        // 发光效果
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowIntensity = 1.0
        }
        
        // 文字出现
        withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.5)) {
            textScale = 1.0
        }
        
        // 粒子爆炸
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            createParticleExplosion()
        }
        
        // 3秒后关闭
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                isActive = false
            }
        }
    }
    
    private func createParticleExplosion() {
        let center = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
        let colors: [Color] = [.cyan, .purple, .pink, .blue, .white]
        
        for _ in 0..<100 {
            let angle = Double.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 50...300)
            let endX = center.x + cos(angle) * distance
            let endY = center.y + sin(angle) * distance
            
            let particle = Particle(
                position: center,
                size: CGFloat.random(in: 4...12),
                color: colors.randomElement()!,
                opacity: 1.0
            )
            
            particles.append(particle)
            
            // 粒子动画
            if let index = particles.firstIndex(where: { $0.id == particle.id }) {
                withAnimation(.easeOut(duration: Double.random(in: 1...2))) {
                    particles[index].position = CGPoint(x: endX, y: endY)
                    particles[index].opacity = 0
                    particles[index].size *= 0.5
                }
            }
        }
        
        // 清理粒子
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            particles.removeAll()
        }
    }
}

#Preview {
    ParticleExplosionSplash(isActive: .constant(true))
}
