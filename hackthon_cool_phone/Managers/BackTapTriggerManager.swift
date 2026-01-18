//
//  BackTapTriggerManager.swift
//  hackthon_cool_phone
//
//  Created by leslie liu on 2026/1/17.
//

//
//  BackTapTriggerManager.swift
//  hackthon_cool_phone
//
//  Created by leslie liu on 2026/1/17.
//

import Foundation
import UIKit
import Combine
import CoreMotion

/// 后背轻点触发器管理
final class BackTapTriggerManager: ObservableObject {
    static let shared = BackTapTriggerManager()
    
    @Published var shouldTriggerCall = false
    
    // 运动管理器
    private let motionManager = CMMotionManager()
    
    // 检测参数
    private let tapThreshold: Double = 2.5        // 轻点阈值
    private let tapTimeWindow: TimeInterval = 0.3 // 两次轻点时间窗口
    private let cooldownTime: TimeInterval = 1.0  // 冷却时间
    
    private var lastTapTime: Date?
    private var tapCount: Int = 0
    private var lastTriggerTime: Date?
    
    private init() {}
    
    // MARK: - 启动检测
    func start() {
        print("🎯 启动后背轻点检测")
        
        guard motionManager.isAccelerometerAvailable else {
            print("❌ 加速度计不可用")
            return
        }
        
        motionManager.accelerometerUpdateInterval = 0.01
        
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let self = self, let data = data else { return }
            self.processAccelerometerData(data)
        }
        
        print("✅ 后背轻点检测已启动")
    }
    
    // MARK: - 停止检测
    func stop() {
        print("🛑 停止后背轻点检测")
        motionManager.stopAccelerometerUpdates()
    }
    
    // MARK: - 处理加速度数据
    private func processAccelerometerData(_ data: CMAccelerometerData) {
        let acceleration = data.acceleration
        
        let magnitude = sqrt(
            pow(acceleration.x, 2) +
            pow(acceleration.y, 2) +
            pow(acceleration.z, 2)
        )
        
        if magnitude > tapThreshold {
            detectTap()
        }
    }
    
    // MARK: - 检测轻点
    private func detectTap() {
        let now = Date()
        
        // 冷却期内不触发
        if let lastTrigger = lastTriggerTime,
           now.timeIntervalSince(lastTrigger) < cooldownTime {
            return
        }
        
        // 首次轻点
        if lastTapTime == nil {
            lastTapTime = now
            tapCount = 1
            print("📍 检测到第 1 次轻点")
            return
        }
        
        // 在时间窗口内的轻点
        if let lastTap = lastTapTime,
           now.timeIntervalSince(lastTap) < tapTimeWindow {
            tapCount += 1
            print("📍 检测到第 \(tapCount) 次轻点")
            
            // 双击触发
            if tapCount == 2 {
                triggerCall()
                resetTapDetection()
            }
        } else {
            // 超出时间窗口，重置
            lastTapTime = now
            tapCount = 1
            print("📍 超时重置，检测到第 1 次轻点")
        }
    }
    
    // MARK: - 触发通话
    private func triggerCall() {
        print("\n🎉 ===== 触发后背双击通话 =====")
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        shouldTriggerCall = true
        lastTriggerTime = Date()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.shouldTriggerCall = false
        }
        
        print("==============================\n")
    }
    
    // MARK: - 重置检测
    private func resetTapDetection() {
        lastTapTime = nil
        tapCount = 0
    }
    
    deinit {
        stop()
    }
}
