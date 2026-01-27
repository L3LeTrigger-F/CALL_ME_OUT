package org.company.coolphone

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.datetime.Clock

object AICallManager {
    private val scope = MainScope()
    
    private val _isProcessing = MutableStateFlow(false)
    val isProcessing = _isProcessing.asStateFlow()
    
    // Global trigger for background intents
    val shouldTriggerIncomingCall = MutableStateFlow(false)
    
    private val _isRecording = MutableStateFlow(false)
    val isRecording = _isRecording.asStateFlow()
    
    private val _currentResponseText = MutableStateFlow("")
    val currentResponseText = _currentResponseText.asStateFlow()
    
    // Delayed Trigger Job
    private var delayedTriggerJob: Job? = null
    
    // Sticky flag for Instant Launch (Shortcut)
    var hasPendingInstantCall: Boolean = false

    
    private var conversationHistory = mutableListOf<Message>()
    private var currentScenario: CallScenario = CallScenario.Urgent
    
    private val audioPlayer = AudioPlayer()
    private val speechRecognizer = SpeechRecognizer()
    
    // Silence Detection
    private var lastSpeechTime: Long = 0
    private var silenceJob: Job? = null
    private var isListening = false
    private var currentPartialText = ""
  //  private var currentPartialText = ""
    private var customPrompt = ""
    private var activeVoiceId: String? = null
    private var isCallActive = false
    private var conversationJob: Job? = null
    
    fun startCall(scenario: CallScenario, customText: String = "", voiceId: String? = null) {
        currentScenario = scenario
        customPrompt = customText
        activeVoiceId = voiceId
        conversationHistory.clear()
        
        // Setup System Prompt
        val prompt = generateSystemPrompt(scenario, customText)
        conversationHistory.add(Message("system", prompt))
        
        isCallActive = true
        conversationJob?.cancel()
        conversationJob = scope.launch {
            try {
                // Generate Greeting
                _isProcessing.value = true
                val greeting = "你好，我是${scenario.rawValue}" 
                
                // Wait, send prompt to LLM to get greeting
                val (audio, text) = MiniMaxClient.sendTextMessage(
                    "（接通电话）请直接用你现在的身份跟我打招呼，语气自然点，不要太书面。简短说明来意。", 
                    conversationHistory,
                    getEffectiveVoiceId(scenario)
                ) 
                
                println("[CoolPhoneDebug] AI Said: $text") // Log AI Speech
                conversationHistory.add(Message("assistant", text))
                _currentResponseText.value = text
                
                // Play Audio
                _isProcessing.value = false
                if (audio.isNotEmpty()) {
                    audioPlayer.play(audio)
                } else {
                    println("[CoolPhoneDebug] Audio Error: Audio is empty, skipping playback.")
                }
                
                // Start Listening Loop
                startListening()
            } catch (e: Exception) {
                println("[CoolPhoneDebug] Error: ${e.message}")
                e.printStackTrace()
                _isProcessing.value = false
                _currentResponseText.value = "Error: ${e.message}"
            }
        }
    }
    
    fun endCall() {
        isCallActive = false
        conversationJob?.cancel()
        conversationJob = null
        stopListening()
        audioPlayer.stop()
        _isRecording.value = false
        _isProcessing.value = false
        setSpeaker(false) // Reset on end
    }

    fun setSpeaker(enabled: Boolean) {
        audioPlayer.setSpeakerphone(enabled)
    }
    
    fun scheduleIncomingCall(delayMs: Long) {
        delayedTriggerJob?.cancel()
        delayedTriggerJob = scope.launch {
            println("[CoolPhoneDebug] Call Scheduled in ${delayMs}ms")
            delay(delayMs)
            shouldTriggerIncomingCall.value = true
        }
    }
    
    fun cancelScheduledCall() {
        delayedTriggerJob?.cancel()
        delayedTriggerJob = null
    }
    
    private fun startListening() {
        if (isListening) return
        isListening = true
        _isRecording.value = true
        
        scope.launch {
            val permitted = speechRecognizer.requestPermissions()
            if (!permitted) {
                println("Speech permission denied")
                return@launch
            }
            
            speechRecognizer.start(
                onResult = { text: String, isFinal: Boolean ->
                    if (isFinal && text.isNotEmpty()) {
                         println("[CoolPhoneDebug] User Said: $text")
                         handleUserMessage(text)
                         currentPartialText = ""
                    } else if (text.isNotEmpty()) {
                         println("[CoolPhoneDebug] User Speaking: $text")
                         currentPartialText = text
                    }
                    lastSpeechTime = Clock.System.now().toEpochMilliseconds()
                },
                onError = {
                    println("[CoolPhoneDebug] Speech Error: $it")
                }
            )
            
            // Silence Check Loop (Manual VAD fallback)
            silenceJob?.cancel()
            silenceJob = scope.launch {
                while(isListening) {
                    delay(100) // Polling faster (100ms)
                    // Lowered timeout from 1500ms to 800ms for snappier turn-taking
                    if (currentPartialText.isNotEmpty() && (Clock.System.now().toEpochMilliseconds() - lastSpeechTime > 800)) {
                        println("[CoolPhoneDebug] Silence Timeout (800ms), using: $currentPartialText")
                        handleUserMessage(currentPartialText)
                        currentPartialText = ""
                    }
                }
            }
        }
    }
    
    private fun stopListening() {
        isListening = false
        _isRecording.value = false
        speechRecognizer.stop()
        silenceJob?.cancel()
    }
    
    fun handleUserMessage(text: String) {
        stopListening()
        
        scope.launch {
            try {
                _isProcessing.value = true
                conversationHistory.add(Message("user", text))
                
                // Play Filler Sound to mask network latency
                audioPlayer.playFiller()
                
                val voiceId = getEffectiveVoiceId(currentScenario)
                val (audio, reply) = MiniMaxClient.sendTextMessage(text, conversationHistory, voiceId)
                
                println("[CoolPhoneDebug] AI Said: $reply")
                conversationHistory.add(Message("assistant", reply))
                _currentResponseText.value = reply
                
                if (!isCallActive) return@launch

                _isProcessing.value = false
                if (audio.isNotEmpty()) {
                    audioPlayer.play(audio)
                }
                
                if (isCallActive) {
                    startListening()
                }
            } catch (e: Exception) {
                 println("AICallManager Loop Error: ${e.message}")
                 _isProcessing.value = false
            }
        }
    }
    
    
    private fun getEffectiveVoiceId(scenario: CallScenario): String {
        return activeVoiceId ?: getVoiceForScenario(scenario)
    }

    private fun getVoiceForScenario(scenario: CallScenario): String {
        return when (scenario) {
            CallScenario.Work -> "male-qn-jingying" // Boss - Elite Male
            CallScenario.Family -> "female-yujie"   // Mom - Mature Female (More realistic than shaonv)
            CallScenario.DateRescue -> "male-qn-qingse" // Bro - Youth Male
            CallScenario.Delivery -> "male-qn-qingse" // Delivery - Youth Male
            CallScenario.Meeting -> "female-yujie"    // Colleague - Mature Female
            CallScenario.Headhunter -> "female-yujie" // HR - Mature Female
            CallScenario.Landlord -> "male-qn-jingying" // Landlord - Elite/Stern Male
            CallScenario.Teacher -> "female-yujie"    // Teacher - Mature Female
            CallScenario.Police -> "male-qn-jingying" // Police - Elite Male
            CallScenario.Scam -> "male-qn-qingse"     // Telemarketer - Youth Male
            CallScenario.OldClassmate -> "male-qn-qingse" // Classmate - Youth/Informal
            CallScenario.PetHospital -> "female-tianmei" // Nurse - Sweet Female
            CallScenario.Bank -> "female-tianmei"      // Bank Service - Sweet/Professional Female
            CallScenario.Interview -> "female-yujie"   // HR - Mature Female
            CallScenario.BlindDate -> "female-tianmei"  // Date - Sweet/Shy Female
            else -> "female-tianmei"
        }
    }
    
    private fun generateSystemPrompt(scenario: CallScenario, customText: String): String {
        val personality = when (scenario) {
            CallScenario.Work -> "你现在是我的老板。性格急躁、强势。你打电话来是因为项目出了紧急问题或者是催我交报告。说话要简短、有力，带有威压感。"
            CallScenario.Family -> "你现在是我的家人（比如姐姐或妈妈）。说话语气亲切、关心，或者是家里有点急事找我。语速正常，带点家常口语。"
            CallScenario.DateRescue -> "你现在是我的好朋友。你假装有急事找我（比如车坏了、失恋了或者急需帮忙），目的是帮我从当前的尴尬约会中脱身。你要表现得很焦急，让我必须马上离开。"
            CallScenario.Delivery -> "你现在是外卖员或快递员。说话干练、语速稍快，背景可能有点吵。你打电话是因为找不到我的具体位置或者需要我下楼取件。"
            CallScenario.Meeting -> "你现在是我的同事。语气由于是工作时间所以比较正经，但私下关系不错。你通知我会议提前了，或者需要我马上确认一个数据。"
            CallScenario.Headhunter -> "你现在是HR或猎头。语气专业、礼貌但带有目的性。你有一个非常好的职位机会想跟我聊聊。"
            CallScenario.Landlord -> "你现在是房东。语气严肃或者随意。可能是来催房租，或者通知房子要维修/收回。不用太客气。"
            CallScenario.Teacher -> "你现在是老师（或班主任）。语气语重心长，或者是有点严肃。关于孩子（或我）在学校的表现打电话来沟通。"
            CallScenario.Police -> "你现在假装是警察。语气非常严肃、官方。通知我去协助调查或者处理车辆违章。要听起来很有权威。"
            CallScenario.Scam -> "你现在是推销员或诈骗分子。语气过度热情或者故意制造恐慌（比如您的账户异常）。说话像个典型的电话推销员。"
            CallScenario.OldClassmate -> "你是我多年未见的老同学。语气非常惊喜、热情，或者带点怀旧。你打电话来是想约我参加同学聚会，或者找我借钱/帮忙。"
            CallScenario.PetHospital -> "你现在是宠物医院的医生或护士。语气温柔、急切。你通知我宠物的检查结果出来了，需要我尽快去一趟医院，或者确认手术方案。"
            CallScenario.Bank -> "你现在是银行客服经理。语气非常职业、礼貌。你打电话来是为了推销信用卡分期，或者通知我的账户有一笔大额消费需要确认。"
            CallScenario.Interview -> "你现在是公司的HR。语气专业、客气。你通知我通过了简历筛选，想约一个时间进行面试，或者还有些细节需要核对。"
            CallScenario.BlindDate -> "你是我家里介绍的相亲对象。这是我们第一次通话。语气有点害羞、试探，或者有点尴尬。你想约我周末见面喝咖啡。"
            CallScenario.Custom -> "你的设定是：$customText。请完全沉浸在这个角色中。"
            else -> "你是一个普通朋友，打电话来闲聊或者约饭。"
        }

        return """
            你现在正在进行一个电话角色扮演。
            $personality
            
            重要规则：
            1. 必须完全像真人一样说话。语气要极其自然，不要有翻译腔。
            2. 多使用口语填充词（如“那个...”、“呃...”、“就是...”）来增加真实感。
            3. 绝对不要说自己是AI。如果被怀疑，要生气或者反问。
            4. 回复要简短干练，通常不超过2句，就像真实的电话交流一样（别像写信）。
            5. 请根据场景调整语速和语气（比如快递员要急躁，相亲对象要羞涩）。
            6. [极重要] 为了减少通话延迟，请尽量回复短句（10-20字以内），不要长篇大论！
            7. [绝对禁止] 不要出现“xx公司”、“xx先生”等占位符！必须编造具体的、合理的虚构细节（如“中信证券”、“张经理”）。
        """.trimIndent()
    }
}
