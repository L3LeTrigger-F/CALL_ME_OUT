package org.company.coolphone

import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.request.header
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.client.request.forms.formData
import io.ktor.client.request.forms.submitFormWithBinaryData
import io.ktor.http.Headers
import io.ktor.http.HttpHeaders
import io.ktor.serialization.kotlinx.json.json
import kotlinx.serialization.json.Json
import io.ktor.util.decodeBase64Bytes
import kotlinx.serialization.Serializable

object MiniMaxClient {
    private val client = HttpClient {
        install(ContentNegotiation) {
            json(Json { 
                ignoreUnknownKeys = true 
                isLenient = true
            })
        }
    }

    private const val GROUP_ID = "2011642032728056634"
    private const val API_KEY = "sk-api-bx_95QbykqrjucyztWiWz9dRPQrn8HsTe0_8onfwsbzZZvKmXnGNdCuvtm9fIeNxQbS8cmEdqBkNGy-peIp4Kj0h2hhIlUTiqgZXL08F-yKJDWbIup5tPuU"
    
    suspend fun sendTextMessage(
        text: String, 
        history: List<Message>,
        voiceId: String = "female-tianmei"
    ): Pair<ByteArray, String> {
        return try {
            // Ensure history messages have names if missing
            val messages = history.map { 
                if (it.name == null) {
                    it.copy(name = if (it.role == "user") "用户" else "MiniMax AI")
                } else it
            }.toMutableList()
            
            messages.add(Message("user", text, "用户"))
            
            val requestBody = ChatRequest(
              //  model = "abab6.5s-chat", // User asked for M2-her but let's check if we should switch.
                model = "M2-her", // Switch to M2-her
                messages = messages,
                temperature = 0.7,
                max_tokens = 100,
                top_p = 0.95
            )
            
            val response: ChatResponse = client.post("https://api.minimaxi.com/v1/text/chatcompletion_v2?GroupId=$GROUP_ID") {
                header("Authorization", "Bearer $API_KEY")
                header("Content-Type", "application/json")
                setBody(requestBody)
            }.body()
            
            val reply = response.choices.firstOrNull()?.message?.content ?: "Error: No response"
            
            val audioData = convertTextToSpeech(reply, voiceId)
            
            Pair(audioData, reply)
            
        } catch (e: Exception) {
            println("[CoolPhoneDebug] MinimaxClient Error: $e")
            Pair(ByteArray(0), "Error: ${e.message}")
        }
    }
    
    suspend fun convertTextToSpeech(text: String, voiceId: String = "female-tianmei"): ByteArray {
        try {
            // Sanitize text: Remove stage directions in (), （）, [], 【】
            val sanitizedText = text.replace(Regex("[\\(（\\[【].*?[\\)）\\]】]"), "").trim()
            
            // If text becomes empty after sanitization (e.g. only had directions), fallback to original or specific silence?
            // Usually won't happen if AI speaks. If empty, use original just in case, or "..."
            val finalText = if (sanitizedText.isBlank()) text else sanitizedText
            
            // Check if it's a file_id (Cloned Voice) or a Preset
            // File IDs usually are just numbers or obscure strings. Presets are "male-..."
            val isCloned = !voiceId.startsWith("male-") && !voiceId.startsWith("female-") && !voiceId.contains("common")
            
            val url = "https://api.minimaxi.com/v1/t2a_v2?GroupId=$GROUP_ID"
            
            // T2A V2 Request Structure
            // We assume voiceId is now a valid registered ID (from createClonedVoice) or a Preset
            val requestBody = T2Av2Request(
                model = "speech-01-hd", // Use HD model for better realism
                text = finalText,
                stream = false,
                voice_setting = VoiceSetting(
                    voice_id = voiceId,
                    speed = 1.0,
                    vol = 1.0,
                    pitch = 0
                ),
                audio_setting = AudioSetting(
                    sample_rate = 24000, // Reduced from 32000 to reduce latency
                    bitrate = 64000,    // Reduced from 128000 (64k is sufficient for voice)
                    format = "mp3",
                    channel = 1
                )
            )

            val httpResponse = client.post(url) {
                header("Authorization", "Bearer $API_KEY")
                header("Content-Type", "application/json")
                setBody(requestBody)
            }
            
            val responseBytes = httpResponse.body<ByteArray>()
            
            println("[CoolPhoneDebug] TTS Response Status: ${httpResponse.status}")
            
            // Check for raw audio/ID3 check
            if (responseBytes.take(3).toByteArray().contentEquals(byteArrayOf(0x49, 0x44, 0x33)) || 
                responseBytes.take(2).toByteArray().contentEquals(byteArrayOf(0xFF.toByte(), 0xF3.toByte())) ||
                responseBytes.take(2).toByteArray().contentEquals(byteArrayOf(0xFF.toByte(), 0xF2.toByte()))) {
                println("[CoolPhoneDebug] TTS returned raw audio data (${responseBytes.size} bytes)")
                return responseBytes
            }
            
            // JSON Error Response
             val responseString = responseBytes.decodeToString()
             println("[CoolPhoneDebug] TTS JSON: ${responseString.take(200)}")
             
             // Try to parse T2A response if it's JSON
             val json = Json { ignoreUnknownKeys = true }
             try {
                val ttsResponse = json.decodeFromString<TTSResponse>(responseString)
                // Only fail if base_resp exists AND status_code is non-zero
                if (ttsResponse.base_resp != null && ttsResponse.base_resp.status_code != 0) {
                     println("TTS Error: ${ttsResponse.base_resp.status_msg}")
                     return ByteArray(0)
                }
                
                ttsResponse.data?.audio?.let { hexAudio ->
                    println("[CoolPhoneDebug] Parsing Audio Hex, length: ${hexAudio.length}")
                    return hexStringToByteArray(hexAudio)
                }
             } catch (e: Exception) {
                 // Not JSON, maybe was raw audio but header check failed?
             }
             
             return ByteArray(0)

        } catch (e: Exception) {
             println("TTS Exception: $e")
             // Fallback if cloned voice failed
             if (voiceId != "female-tianmei") {
                 println("TTS Failed with custom voice, retrying with default...")
                 return convertTextToSpeech(text, "female-tianmei")
             }
             return ByteArray(0)
        }
    }
    
    private fun hexStringToByteArray(s: String): ByteArray {
        val len = s.length
        val data = ByteArray(len / 2)
        var i = 0
        while (i < len) {
            val high = s[i].digitToInt(16)
            val low = s[i + 1].digitToInt(16)
            data[i / 2] = ((high shl 4) + low).toByte()
            i += 2
        }
        return data
    }
    
    suspend fun uploadVoiceFile(fileData: ByteArray): String? {
        // Mocking Upload URL - assuming /v1/files/upload or similar for MiniMax
        // Based on common MiniMax patterns: https://api.minimax.chat/v1/files/upload?GroupId=...
        try {
             val response: FileUploadResponse = client.submitFormWithBinaryData(
                url = "https://api.minimaxi.com/v1/files/upload?GroupId=$GROUP_ID",
                formData = formData {
                    append("file", fileData, Headers.build {
                        append(HttpHeaders.ContentType, "audio/mpeg")
                        append(HttpHeaders.ContentDisposition, "filename=\"voice_sample.m4a\"")
                    })
                    append("purpose", "voice_clone")
                }
            ) {
                header("Authorization", "Bearer $API_KEY")
            }.body()
            
            if (response.base_resp?.status_code == 0) {
                val fileId = response.file?.file_id
                if (fileId != null) {
                    return createClonedVoice(fileId)
                }
            } else {
                println("Upload Failed: ${response.base_resp?.status_msg}")
            }
        } catch (e: Exception) {
            println("Upload Exception: $e")
        }
        return null
    }

    // Step 2: Create Voice from File ID (Restored)
    private suspend fun createClonedVoice(fileId: String): String? {
        try {
            // Pure alphanumeric ID
            val simpleId = "UserVoice${(kotlinx.datetime.Clock.System.now().toEpochMilliseconds() % 100000)}"
            println("[CoolPhoneDebug] creating voice with ID: $simpleId from file: $fileId")
            
            // Try passing file_id as Long (if parseable)
            val fileIdLong = fileId.toLongOrNull() ?: return null
            
            val requestBody = VoiceCloneRequest(
                file_id = fileIdLong,
                voice_id = simpleId,
                noise_reduction = true // optional param often required?
            )
            
            val response: VoiceCloneResponse = client.post("https://api.minimaxi.com/v1/voice_clone?GroupId=$GROUP_ID") {
                header("Authorization", "Bearer $API_KEY")
                header("Content-Type", "application/json")
                setBody(requestBody)
            }.body()
            
            println("[CoolPhoneDebug] Voice Clone Response: ${response.base_resp?.status_msg}")
            
            if (response.base_resp?.status_code == 0) {
                // Return the successful ID? 
                // Response might contain the actual ID if server modified it, or we use ours.
                return response.voice_id ?: simpleId
            } else {
                 println("Voice Clone Failed: ${response.base_resp?.status_msg}")
                 if (response.base_resp?.status_msg?.contains("forbidden") == true) {
                     return "forbidden_error"
                 }
            }
        } catch (e: Exception) {
             println("Voice Clone Exception: $e")
        }
        return null
    }
    

}

// DTOs
@Serializable
data class ChatRequest(
    val model: String,
    val messages: List<Message>,
    val temperature: Double,
    val max_tokens: Int,
    val top_p: Double
)

@Serializable
data class Message(val role: String, val content: String, val name: String? = null)

@Serializable
data class ChatResponse(val choices: List<Choice>)

@Serializable
data class Choice(val message: Message)

@Serializable
data class TTSRequest(
    val voice_id: String,
    val text: String,
    val model: String,
    val speed: Double = 1.0,
    val vol: Double = 1.0,
    val pitch: Int = 0
)

@Serializable
data class T2Av2Request(
    val model: String,
    val text: String,
    val stream: Boolean,
    val voice_setting: VoiceSetting,
    val audio_setting: AudioSetting
)

@Serializable
data class VoiceSetting(
    val voice_id: String,
    val speed: Double,
    val vol: Double,
    val pitch: Int
)

@Serializable
data class AudioSetting(
    val sample_rate: Int,
    val bitrate: Int,
    val format: String,
    val channel: Int
)

@Serializable
data class TTSResponse(
    val base_resp: BaseResp? = null,
    val data: TTSData? = null, // V2 Hex data inside object
    val extra_info: ExtraInfo? = null
)

@Serializable
data class TTSData(val audio: String? = null)

@Serializable
data class BaseResp(val status_code: Int, val status_msg: String)

@Serializable
data class ExtraInfo(val audio_file: String? = null)

@Serializable
data class FileUploadResponse(
    val base_resp: BaseResp? = null,
    val file: FileInfo? = null
)

@Serializable
data class FileInfo(val file_id: String)

@Serializable
data class VoiceCloneRequest(
    val file_id: Long,
    val voice_id: String? = null,
    val noise_reduction: Boolean = true
)

@Serializable
data class VoiceCloneResponse(
    val base_resp: BaseResp? = null,
    val voice_id: String? = null,
    val file_id: String? = null
)
