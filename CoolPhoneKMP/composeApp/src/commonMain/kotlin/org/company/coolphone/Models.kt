package org.company.coolphone

import androidx.compose.ui.graphics.Color
import kotlinx.serialization.Serializable
import kotlinx.datetime.Clock
import kotlinx.datetime.Instant
import kotlin.random.Random

// MARK: - 通话设置数据模型
@Serializable
data class CallSettings(
    var callerName: String = "王铁柱",
    var callerNumber: String = "138 8888 8888",
    var callerAvatar: String = "person_circle_fill", // SF Symbols map to resource name
    var callerRelation: String = "朋友",
    var scenario: CallScenario = CallScenario.Urgent,
    var customScenarioText: String = "我是你的AI助手，请告诉我怎么配合你演戏。",
    var customVoiceId: String? = null,
    var ringtone: Ringtone = Ringtone.Classic,
    var delaySeconds: Int = 0 // Delay in seconds (0 = Immediate)
)

typealias Bool = Boolean

// MARK: - 通话对象预设
data class Contact(
    val id: String = generateUUID(),
    val name: String,
    val number: String,
    val avatar: String,
    val relation: String,
    val color: Long // Color as Long (ARGB) or similar, for simplicity storing as hex long
) {
    companion object {
        val presets: List<Contact> = listOf(
            Contact(name = "老板", number = "138 0000 0001", avatar = "briefcase_fill", relation = "上司", color = 0xFFFF0000),
            Contact(name = "妈妈", number = "139 0000 0002", avatar = "heart_fill", relation = "家人", color = 0xFFFFC0CB), // Pink
            Contact(name = "女朋友", number = "137 0000 0003", avatar = "heart_circle_fill", relation = "恋人", color = 0xFFFF0000),
            Contact(name = "医生", number = "136 0000 0004", avatar = "cross_case_fill", relation = "医生", color = 0xFF008000),
            Contact(name = "快递员", number = "135 0000 0005", avatar = "shippingbox_fill", relation = "快递", color = 0xFFFFA500),
            Contact(name = "客户", number = "134 0000 0006", avatar = "person_2_fill", relation = "客户", color = 0xFF0000FF),
            Contact(name = "同事", number = "133 0000 0007", avatar = "person_3_fill", relation = "同事", color = 0xFF00FFFF),
            Contact(name = "朋友", number = "132 0000 0008", avatar = "person_fill", relation = "朋友", color = 0xFF800080)
        )
    }
}

data class ConversationMessage(
    val id: String = generateUUID(),
    val text: String,
    val isUser: Bool,
    val timestamp: Long = Clock.System.now().toEpochMilliseconds()
)

// MARK: - 通话剧情
@Serializable
enum class CallScenario(val rawValue: String, val description: String, val icon: String, val color: Long) {
    Urgent("紧急事件", "有紧急事情需要处理", "exclamationmark_triangle_fill", 0xFFFFA726),
    Work("工作加班", "老板通知必须立即加班", "briefcase_fill", 0xFF29B6F6),
    Family("家庭聚餐", "父母询问何时回家吃饭", "house_fill", 0xFFEF5350),
    DateRescue("相亲救急", "假装前任求复合", "heart_slash_fill", 0xFFEC407A),
    Delivery("快递外卖", "外卖到了无人签收", "shippingbox_fill", 0xFFFFCA28),
    Meeting("临时会议", "紧急召开跨国会议", "calendar_badge_clock", 0xFFAB47BC),
    Headhunter("猎头挖人", "高薪职位邀请面试", "person_crop_circle_badge_checkmark", 0xFF42A5F5),
    Landlord("房东催租", "通知房租涨价事宜", "building_2_fill", 0xFF8D6E63),
    Teacher("老师家访", "班主任反映在校情况", "book_fill", 0xFF66BB6A),
    Police("社区民警", "配合社区安全调查", "shield_fill", 0xFF5C6BC0),
    Scam("诈骗电话", "假装推销以拖延时间", "phone_down_circle_fill", 0xFF78909C),
    OldClassmate("老同学", "多年未见的老同学叙旧", "person_2_wave_2_fill", 0xFF8E24AA),
    PetHospital("宠物医院", "通知宠物检查结果", "heart_text_square_fill", 0xFFD81B60),
    Bank("银行客服", "信用卡或理财业务", "dollarsign_circle_fill", 0xFF00897B),
    Interview("面试通知", "HR通知面试时间和地点", "person_crop_circle_badge_checkmark", 0xFF42A5F5),
    BlindDate("相亲对象", "第一次接触的相亲对象", "heart_fill", 0xFFE91E63),
    Custom("自定义", "自定义剧情内容", "pencil_circle_fill", 0xFFFF7043);

    companion object {
        fun getAll() = values().toList()
    }
}

// MARK: - 来电铃声
@Serializable
enum class Ringtone(val rawValue: String, val systemSoundID: Int) {
    Classic("经典", 1005),
    Digital("电子", 1007);
    
    companion object {
        fun getAll() = values().toList()
    }
}

// Simple UUID generator fallback
fun generateUUID(): String = Random.nextLong().toString()
