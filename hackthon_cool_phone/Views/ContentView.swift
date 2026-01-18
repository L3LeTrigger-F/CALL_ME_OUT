//
//  BackTapTriggerManager.swift
//
//  Created by leslie liu on 2026/1/17.
//

import Foundation
import UIKit
import Combine
import CoreMotion
import SwiftUI
import SwiftData
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
                ZStack {
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
            
            Text("快速生成虚拟来电，帮助你优雅地脱离尴尬场景。支持音量键快捷触发，自定义来电信息，让你的脱身更加自然。")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .background(
            ZStack {
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
                ZStack {
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
                    
                    Image(systemName: icon)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .white.opacity(0.5), radius: 5)
                }
                
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
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.05))
                    
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
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                shimmerOffset = 400
            }
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
                        Text("截图快捷键触发来电")
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
                        Text("截图快捷键即可触发虚拟来电")
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
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
                
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

// MARK: - 提示行组件
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

// MARK: - ===========================================
// MARK: - 主视图
// MARK: - ===========================================

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    // 使用新的通话设置模型
    @State private var callSettings = CallSettings()
    @State private var showIncomingCall = false
    
    // 音量键监听
    @ObservedObject private var screenshotManager = ScreenshotTriggerManager.shared
    @State private var isVolumeMonitoringEnabled = true
    
    // Toast 提示
    @State private var showToast = false
    @State private var toastMessage = ""
    
    // 导航状态
    @State private var showCallSettings = false
    @State private var showTestCall = false
    
    // 动画状态
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var customScenarioText = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 动态背景
                AnimatedBackground()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // 顶部介绍 Bar
                        CoolAppIntroductionBar(
                            rotationAngle: $rotationAngle,
                            pulseScale: $pulseScale
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 30)
                        
                        // 主功能卡片
                        VStack(spacing: 20) {
                            // 通话设置卡片
                            NeonFeatureCard(
                                icon: "phone.circle.fill",
                                title: "通话设置",
                                description: "自定义来电信息和快捷方式",
                                primaryColor: .cyan,
                                secondaryColor: .blue,
                                action: {
                                    showCallSettings = true
                                }
                            )
                            
                            // 测试来电卡片
                            NeonFeatureCard(
                                icon: "phone.badge.waveform.fill",
                                title: "测试来电",
                                description: "立即触发虚拟来电或定时触发",
                                primaryColor: .green,
                                secondaryColor: .mint,
                                action: {
                                    showTestCall = true
                                }
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // 快捷提示区域
                        GlassmorphicTipsCard(
                            isVolumeMonitoringEnabled: $isVolumeMonitoringEnabled
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 30)
                        
                        Color.clear.frame(height: 50)
                    }
                }
                
                // Toast 提示
                if showToast {
                    CoolToast(message: toastMessage, isShowing: $showToast)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .sheet(isPresented: $showCallSettings) {
                EnhancedCallSettingsView(
                    settings: $callSettings,
                    isVolumeMonitoringEnabled: $isVolumeMonitoringEnabled
                )
            }
            .sheet(isPresented: $showTestCall) {
                CoolTestCallView(
                    callerName: callSettings.callerName,
                    callerNumber: callSettings.callerNumber,
                    showIncomingCall: $showIncomingCall,
                    showToast: $showToast,
                    toastMessage: $toastMessage
                )
            }
            .fullScreenCover(isPresented: $showIncomingCall) {
                IncomingCallView(
                    callerName: callSettings.callerName,
                    callerNumber: callSettings.callerNumber,
                    scenario: callSettings.scenario,
                    customScenarioText: customScenarioText,
                    isPresented: $showIncomingCall
                )
            }
        }
        .onAppear {
            startAnimations()
            ScreenshotTriggerManager.shared.start()
            
            if isVolumeMonitoringEnabled {
                toastMessage = "提示：截屏可快速触发来电"
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    showToast = true
                }
            }
        }
        .onChange(of: screenshotManager.shouldTriggerCall) { _, shouldTrigger in
            if shouldTrigger && isVolumeMonitoringEnabled {
                toastMessage = "✅ 检测到截屏，触发来电"
                showToast = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showIncomingCall = true
                }
            }
        }
    }
    
    private func startAnimations() {
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
        
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            pulseScale = 1.2
        }
    }
}

// MARK: - 测试来电视图
struct CoolTestCallView: View {
    @Environment(\.dismiss) var dismiss
    let callerName: String
    let callerNumber: String
    @Binding var showIncomingCall: Bool
    @Binding var showToast: Bool
    @Binding var toastMessage: String
    
    @State private var pulseAnimation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground()
                
                ScrollView {
                    VStack(spacing: 30) {
                        VStack(spacing: 24) {
                            Text("来电预览")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            
                            VStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            RadialGradient(
                                                gradient: Gradient(colors: [
                                                    Color.cyan.opacity(0.4),
                                                    Color.clear
                                                ]),
                                                center: .center,
                                                startRadius: 0,
                                                endRadius: 70
                                            )
                                        )
                                        .frame(width: 140, height: 140)
                                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                                        .blur(radius: 10)
                                    
                                    Circle()
                                        .fill(
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
                                        .frame(width: 100, height: 100)
                                        .shadow(color: .cyan, radius: 20)
                                    
                                    Text(String(callerName.prefix(1)))
                                        .font(.system(size: 42, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                Text(callerName)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.cyan, .white, .cyan]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                
                                Text(callerNumber)
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.white.opacity(0.05))
                                
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.cyan.opacity(0.6),
                                                Color.blue.opacity(0.3),
                                                Color.purple.opacity(0.6)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            }
                        )
                        .shadow(color: .cyan.opacity(0.3), radius: 25, x: 0, y: 10)
                        .padding(.horizontal, 20)
                        .padding(.top, 30)
                        
                        VStack(spacing: 16) {
                            NeonButton(
                                icon: "phone.fill",
                                title: "立即触发来电",
                                primaryColor: .green,
                                secondaryColor: .mint,
                                action: {
                                    dismiss()
                                    showIncomingCall = true
                                }
                            )
                            
                            NeonButton(
                                icon: "clock.fill",
                                title: "5秒后触发",
                                primaryColor: .blue,
                                secondaryColor: .cyan,
                                action: {
                                    dismiss()
                                    toastMessage = "⏰ 5秒后触发来电"
                                    showToast = true
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                        showIncomingCall = true
                                    }
                                }
                            )
                            
                            NeonButton(
                                icon: "timer",
                                title: "10秒后触发",
                                primaryColor: .orange,
                                secondaryColor: .yellow,
                                action: {
                                    dismiss()
                                    toastMessage = "⏰ 10秒后触发来电"
                                    showToast = true
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                                        showIncomingCall = true
                                    }
                                }
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 10) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.cyan)
                                Text("使用提示")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                TipRow(icon: "checkmark.circle", text: "选择延时触发可以让你有时间准备", color: .green)
                                TipRow(icon: "checkmark.circle", text: "立即触发适合紧急情况快速脱身", color: .blue)
                                TipRow(icon: "checkmark.circle", text: "也可以使用音量键快捷触发", color: .orange)
                            }
                        }
                        .padding(24)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white.opacity(0.05))
                                
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                            }
                        )
                        .padding(.horizontal, 20)
                        
                        Color.clear.frame(height: 30)
                    }
                }
            }
            .navigationTitle("测试来电")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                    .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
