//
//  EnhancedCallSettingsView.swift
//  hackthon_cool_phone
//
//  Created by leslie liu on 2026/1/17.
//

import SwiftUI
import AVFoundation
import AudioToolbox
struct EnhancedCallSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var settings: CallSettings
    @Binding var isVolumeMonitoringEnabled: Bool
    
    @State private var showContactPicker = false
    @State private var showScenarioPicker = false
    @State private var showRingtonePicker = false
    @State private var showTimePicker = false
    @State private var customScenarioText = ""
    
    // 音频播放器
    @State private var audioPlayer: AVAudioPlayer?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 动态背景
                AnimatedBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 1. 通话对象选择
                        SettingSection(
                            title: "通话对象",
                            icon: "person.circle.fill",
                            iconColor: .cyan
                        ) {
                            Button(action: { showContactPicker = true }) {
                                ContactDisplayCard(
                                    name: settings.callerName,
                                    number: settings.callerNumber,
                                    avatar: settings.callerAvatar,
                                    relation: settings.callerRelation
                                )
                            }
                        }
                        
                        // 2. 通话剧情设置
                        SettingSection(
                            title: "通话剧情",
                            icon: "text.bubble.fill",
                            iconColor: .purple
                        ) {
                            Button(action: { showScenarioPicker = true }) {
                                ScenarioDisplayCard(scenario: settings.scenario)
                            }
                            
                            if settings.scenario == .custom {
                                CustomScenarioInput(text: $customScenarioText)
                            }
                        }
                        
                        // 3. 来电铃声设置
                        SettingSection(
                            title: "来电铃声",
                            icon: "speaker.wave.3.fill",
                            iconColor: .orange
                        ) {
                            Button(action: { showRingtonePicker = true }) {
                                RingtoneDisplayCard(
                                    ringtone: settings.ringtone,
                                    onPlay: { playRingtone(settings.ringtone) }
                                )
                            }
                        }
                        
                        // 4. 来电时间设置
                        SettingSection(
                            title: "来电时间",
                            icon: "clock.fill",
                            iconColor: .green
                        ) {
                            VStack(spacing: 16) {
                                Toggle(isOn: $settings.isScheduled) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "alarm.fill")
                                            .foregroundColor(.green)
                                        Text("定时来电")
                                            .foregroundColor(.white)
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: .green))
                                
                                if settings.isScheduled {
                                    Button(action: { showTimePicker = true }) {
                                        TimeDisplayCard(time: settings.scheduledTime)
                                    }
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        
                        // 5. 快捷方式设置
                        SettingSection(
                            title: "快捷方式",
                            icon: "bolt.fill",
                            iconColor: .yellow
                        ) {
                            Toggle(isOn: $isVolumeMonitoringEnabled) {
                                HStack(spacing: 10) {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .foregroundColor(.yellow)
                                    Text("双击音量键触发来电")
                                        .foregroundColor(.white)
                                }
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .yellow))
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        
                        Color.clear.frame(height: 30)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("通话设置")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                    .font(.system(size: 16, weight: .semibold))
                }
            }
            .sheet(isPresented: $showContactPicker) {
                ContactPickerView(settings: $settings)
            }
            .sheet(isPresented: $showScenarioPicker) {
                ScenarioPickerView(scenario: $settings.scenario)
            }
            .sheet(isPresented: $showRingtonePicker) {
                RingtonePickerView(
                    ringtone: $settings.ringtone,
                    onPlay: { ringtone in playRingtone(ringtone) }
                )
            }
            .sheet(isPresented: $showTimePicker) {
                TimePickerView(scheduledTime: $settings.scheduledTime)
            }
        }
    }
    
    // MARK: - 播放铃声
    private func playRingtone(_ ringtone: Ringtone) {
        AudioServicesPlaySystemSound(ringtone.systemSoundID)
    }
}

// MARK: - 设置区块组件
struct SettingSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.system(size: 16, weight: .bold))
                }
                
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // 内容
            content
        }
    }
}

// MARK: - 联系人显示卡片
struct ContactDisplayCard: View {
    let name: String
    let number: String
    let avatar: String
    let relation: String
    
    var body: some View {
        HStack(spacing: 16) {
            // 头像
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.cyan, .blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: avatar)
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
            
            // 信息
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(relation)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.cyan.opacity(0.2))
                        )
                }
                
                Text(number)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.cyan)
                .font(.system(size: 14, weight: .bold))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - 剧情显示卡片
struct ScenarioDisplayCard: View {
    let scenario: CallScenario
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(scenario.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: scenario.icon)
                    .font(.system(size: 24))
                    .foregroundColor(scenario.color)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(scenario.rawValue)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text(scenario.description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(scenario.color)
                .font(.system(size: 14, weight: .bold))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(scenario.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - 自定义剧情输入
struct CustomScenarioInput: View {
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("自定义剧情内容")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            TextEditor(text: $text)
                .frame(height: 100)
                .padding(12)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .foregroundColor(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
        )
    }
}

// MARK: - 铃声显示卡片
struct RingtoneDisplayCard: View {
    let ringtone: Ringtone
    let onPlay: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "bell.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(ringtone.rawValue)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text("点击右侧按钮试听")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            // 播放按钮
            Button(action: onPlay) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "play.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 14))
                }
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(.orange)
                .font(.system(size: 14, weight: .bold))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - 时间显示卡片
struct TimeDisplayCard: View {
    let time: Date?
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "clock.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("定时来电")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                if let time = time {
                    Text(time, style: .time)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.green)
                } else {
                    Text("点击设置时间")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.green)
                .font(.system(size: 14, weight: .bold))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - 联系人选择器
struct ContactPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var settings: CallSettings
    @State private var customName = ""
    @State private var customNumber = ""
    @State private var showCustomInput = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // 预设联系人
                        ForEach(Contact.presets) { contact in
                            Button(action: {
                                settings.callerName = contact.name
                                settings.callerNumber = contact.number
                                settings.callerAvatar = contact.avatar
                                settings.callerRelation = contact.relation
                                dismiss()
                            }) {
                                ContactRow(contact: contact)
                            }
                        }
                        
                        // 自定义联系人
                        Button(action: { showCustomInput = true }) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.cyan.opacity(0.2))
                                        .frame(width: 60, height: 60)
                                    
                                    Image(systemName: "person.badge.plus.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.cyan)
                                }
                                
                                Text("自定义联系人")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.cyan)
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.cyan.opacity(0.5), lineWidth: 2)
                                    )
                            )
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("选择通话对象")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") { dismiss() }
                        .foregroundColor(.cyan)
                }
            }
            .sheet(isPresented: $showCustomInput) {
                CustomContactInputView(settings: $settings)
            }
        }
    }
}

// MARK: - 联系人行
struct ContactRow: View {
    let contact: Contact
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [contact.color, contact.color.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: contact.avatar)
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(contact.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(contact.relation)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(contact.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(contact.color.opacity(0.2))
                        )
                }
                
                Text(contact.number)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(contact.color)
                .font(.system(size: 24))
                .opacity(0) // 选中时显示
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(contact.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - 自定义联系人输入
struct CustomContactInputView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var settings: CallSettings
    @State private var name = ""
    @State private var number = ""
    @State private var selectedRelation = "朋友"
    
    let relations = ["朋友", "家人", "同事", "客户", "其他"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground()
                
                Form {
                    Section("基本信息") {
                        TextField("姓名", text: $name)
                        TextField("电话号码", text: $number)
                            .keyboardType(.phonePad)
                    }
                    
                    Section("关系") {
                        Picker("关系", selection: $selectedRelation) {
                            ForEach(relations, id: \.self) { relation in
                                Text(relation).tag(relation)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("自定义联系人")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        settings.callerName = name
                        settings.callerNumber = number
                        settings.callerRelation = selectedRelation
                        settings.callerAvatar = "person.circle.fill"
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                    .disabled(name.isEmpty || number.isEmpty)
                }
            }
        }
    }
}

// MARK: - 剧情选择器
struct ScenarioPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var scenario: CallScenario
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground()
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(CallScenario.allCases) { item in
                            Button(action: {
                                scenario = item
                                if item != .custom {
                                    dismiss()
                                }
                            }) {
                                ScenarioOptionRow(
                                    scenario: item,
                                    isSelected: scenario == item
                                )
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("选择通话剧情")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundColor(.cyan)
                }
            }
        }
    }
}

// MARK: - 剧情选项行
struct ScenarioOptionRow: View {
    let scenario: CallScenario
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(scenario.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: scenario.icon)
                    .font(.system(size: 24))
                    .foregroundColor(scenario.color)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(scenario.rawValue)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text(scenario.description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(2)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(scenario.color)
                    .font(.system(size: 24))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(isSelected ? 0.1 : 0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(scenario.color.opacity(isSelected ? 0.6 : 0.3), lineWidth: isSelected ? 2 : 1)
                )
        )
    }
}

// MARK: - 铃声选择器
struct RingtonePickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var ringtone: Ringtone
    let onPlay: (Ringtone) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground()
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(Ringtone.allCases) { item in
                            Button(action: {
                                ringtone = item
                                dismiss()
                            }) {
                                RingtoneOptionRow(
                                    ringtone: item,
                                    isSelected: ringtone == item,
                                    onPlay: { onPlay(item) }
                                )
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("选择来电铃声")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundColor(.cyan)
                }
            }
        }
    }
}

// MARK: - 铃声选项行
struct RingtoneOptionRow: View {
    let ringtone: Ringtone
    let isSelected: Bool
    let onPlay: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "bell.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
            }
            
            Text(ringtone.rawValue)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            // 播放按钮
            Button(action: onPlay) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "play.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 14))
                }
            }
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 24))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(isSelected ? 0.1 : 0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(isSelected ? 0.6 : 0.3), lineWidth: isSelected ? 2 : 1)
                )
        )
    }
}

// MARK: - 时间选择器
struct TimePickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var scheduledTime: Date?
    @State private var selectedTime = Date()
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // 时钟图标
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.green.opacity(0.4),
                                        Color.clear
                                    ]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)
                        
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.green, .mint]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "clock.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }
                    
                    // 时间选择器
                    DatePicker(
                        "选择时间",
                        selection: $selectedTime,
                        displayedComponents: [.hourAndMinute]
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 30)
                    
                    // 时间显示
                    Text(selectedTime, style: .time)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.green, .mint]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Spacer()
                }
            }
            .navigationTitle("设置来电时间")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("确定") {
                        scheduledTime = selectedTime
                        dismiss()
                    }
                    .foregroundColor(.green)
                    .font(.system(size: 16, weight: .semibold))
                }
            }
        }
    }
}
