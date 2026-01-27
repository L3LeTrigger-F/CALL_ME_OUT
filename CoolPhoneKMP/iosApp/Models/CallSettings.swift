import Foundation
import SwiftUI
import AudioToolbox
// MARK: - 通话设置数据模型
struct CallSettings {
    var callerName: String = "王铁柱"
    var callerNumber: String = "138 8888 8888"
    var callerAvatar: String = "person.circle.fill"
    var callerRelation: String = "朋友"
    
    var scenario: CallScenario = .urgent
    var ringtone: Ringtone = .classic
    var scheduledTime: Date?
    var isScheduled: Bool = false
}

// MARK: - 通话对象预设
struct Contact: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let number: String
    let avatar: String
    let relation: String
    let color: Color
}
struct ConversationMessage: Identifiable, Equatable {
    let id: UUID
    let text: String
    let isUser: Bool
    let timestamp: Date
    
    // 自定义初始化器（可选，方便创建）
    init(id: UUID = UUID(), text: String, isUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.timestamp = timestamp
    }
}
// MARK: - 预设联系人列表
extension Contact {
    static let presets: [Contact] = [
        Contact(name: "老板", number: "138 0000 0001", avatar: "briefcase.fill", relation: "上司", color: .red),
        Contact(name: "妈妈", number: "139 0000 0002", avatar: "heart.fill", relation: "家人", color: .pink),
        Contact(name: "女朋友", number: "137 0000 0003", avatar: "heart.circle.fill", relation: "恋人", color: .red),
        Contact(name: "医生", number: "136 0000 0004", avatar: "cross.case.fill", relation: "医生", color: .green),
        Contact(name: "快递员", number: "135 0000 0005", avatar: "shippingbox.fill", relation: "快递", color: .orange),
        Contact(name: "客户", number: "134 0000 0006", avatar: "person.2.fill", relation: "客户", color: .blue),
        Contact(name: "同事", number: "133 0000 0007", avatar: "person.3.fill", relation: "同事", color: .cyan),
        Contact(name: "朋友", number: "132 0000 0008", avatar: "person.fill", relation: "朋友", color: .purple),
    ]
}

// MARK: - 通话剧情
enum CallScenario: String, CaseIterable, Identifiable {
    case urgent = "紧急事件"
    case work = "工作安排"
    case family = "家庭事务"
    case health = "健康问题"
    case delivery = "快递到达"
    case meeting = "会议通知"
    case emergency = "突发状况"
    case custom = "自定义"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .urgent: return "exclamationmark.triangle.fill"
        case .work: return "briefcase.fill"
        case .family: return "house.fill"
        case .health: return "cross.case.fill"
        case .delivery: return "shippingbox.fill"
        case .meeting: return "calendar.badge.clock"
        case .emergency: return "alarm.fill"
        case .custom: return "pencil.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .urgent: return .orange
        case .work: return .blue
        case .family: return .pink
        case .health: return .green
        case .delivery: return .orange
        case .meeting: return .purple
        case .emergency: return .red
        case .custom: return .cyan
        }
    }
    
    var description: String {
        switch self {
        case .urgent: return "有紧急事情需要处理"
        case .work: return "老板安排重要工作"
        case .family: return "家里有事需要帮忙"
        case .health: return "医生通知检查结果"
        case .delivery: return "快递已到需要签收"
        case .meeting: return "临时会议马上开始"
        case .emergency: return "突发紧急状况"
        case .custom: return "自定义剧情内容"
        }
    }
}

// MARK: - 来电铃声
enum Ringtone: String, CaseIterable, Identifiable {
    case classic = "经典"
    case digital = "电子"

    var id: String { rawValue }

    var systemSoundID: SystemSoundID {
        switch self {
        case .classic: return 1005
        case .digital: return 1007
        }
    }
}
