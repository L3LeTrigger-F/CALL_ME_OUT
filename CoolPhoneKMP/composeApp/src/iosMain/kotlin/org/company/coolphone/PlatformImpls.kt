@file:OptIn(ExperimentalForeignApi::class)
package org.company.coolphone

import platform.AudioToolbox.AudioServicesPlaySystemSound
import platform.AudioToolbox.kSystemSoundID_Vibrate
import platform.posix.memcpy

import platform.CoreMotion.CMMotionManager
import platform.AVFAudio.AVAudioSession
import platform.AVFAudio.AVAudioSessionCategoryPlayAndRecord
import platform.AVFAudio.AVAudioSessionModeVoiceChat
import platform.AVFAudio.AVAudioSessionPortOverrideSpeaker
import platform.AVFAudio.AVAudioSessionPortOverrideNone
import platform.AVFAudio.setActive

import platform.Foundation.NSOperationQueue
import platform.UIKit.UIApplicationUserDidTakeScreenshotNotification
import platform.Foundation.NSNotificationCenter
import platform.AVFAudio.AVAudioPlayer
import platform.AVFAudio.AVAudioRecorder // Restored

import platform.Foundation.NSData
import platform.Foundation.create
import platform.Foundation.NSURL
import platform.Foundation.dataWithContentsOfURL
import kotlinx.cinterop.addressOf
import kotlinx.cinterop.usePinned
import kotlinx.cinterop.useContents
import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.coroutines.delay
import kotlinx.coroutines.suspendCancellableCoroutine // Restored
import kotlin.coroutines.resume
import kotlinx.coroutines.launch

import platform.Speech.SFSpeechRecognizer
import platform.Speech.SFSpeechAudioBufferRecognitionRequest
import platform.Speech.SFSpeechRecognitionTask
import kotlinx.datetime.Clock
import platform.AVFAudio.AVAudioEngine
import platform.AVFAudio.AVAudioSessionCategoryRecord
import platform.AVFAudio.AVAudioSessionModeMeasurement
import platform.Foundation.NSLocale

import platform.UIKit.UIDocumentPickerViewController
import platform.UIKit.UIDocumentPickerDelegateProtocol
import platform.UIKit.UIDocumentPickerMode
import platform.UIKit.UIApplication
import platform.darwin.NSObject

// Extension to convert ByteArray to NSData
fun ByteArray.toNSData(): NSData = usePinned {
    NSData.create(bytes = it.addressOf(0), length = this.size.toULong())
}

actual class AudioPlayer {
    private var player: AVAudioPlayer? = null
    private val scope = kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.Main)
    private var ringtoneJob: kotlinx.coroutines.Job? = null


    actual suspend fun play(data: ByteArray) {
        stop()
        
        val audioSession = AVAudioSession.sharedInstance()
        // Use PlayAndRecord to allow Receiver (earpiece) vs Speaker routing
        try {
            audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, mode = AVAudioSessionModeVoiceChat, options = 0u, error = null)
            audioSession.setActive(true, error = null)
        } catch (e: Exception) {
            println("AudioSession Error: $e")
        }
        
        val nsData = data.toNSData()
        
        try {
            val player = AVAudioPlayer(data = nsData, error = null)
            this.player = player
            player.prepareToPlay()
            player.play()
            
            val duration = player.duration
             kotlinx.coroutines.delay((duration * 1000).toLong())
             
        } catch (e: Exception) {
            println("Audio play error: $e")
        }
    }

    actual fun stop() {
        if (player?.isPlaying() == true) {
            player?.stop()
        }
        player = null
        ringtoneJob?.cancel()
        ringtoneJob = null
    }


    actual fun playSystemRingtone() {
        // Stop any existing loop
        stop()
        
        ringtoneJob = scope.launch {
            while (true) {
                // ID 1151 is FaceTime Ringing (approx 1.5s - 2s)
                AudioServicesPlaySystemSound(1151u)
                delay(2000) // Loop every 2 seconds
            }
        }
    }

    actual fun setSpeakerphone(enabled: Boolean) {
        val session = AVAudioSession.sharedInstance()
        try {
            if (enabled) {
                session.overrideOutputAudioPort(AVAudioSessionPortOverrideSpeaker, error = null)
            } else {
                session.overrideOutputAudioPort(AVAudioSessionPortOverrideNone, error = null)
            }
        } catch (e: Exception) {
            println("Error setting speakerphone: $e")
        }
    }

    actual fun playFiller() {
        // 1104 = Tock, 1105 = TockLight, 1057 = Tink, 1003 = Received Message (old)
        // 1113/1114 = Key press
        // Using 1103 (Tock) for a subtle "I heard you" acknowledgement
        AudioServicesPlaySystemSound(1103u)
    }
}

actual class Accelerometer {
    private val motionManager = CMMotionManager()
    
    actual fun start(onUpdate: (x: Double, y: Double, z: Double) -> Unit) {
        if (motionManager.accelerometerAvailable) {
            motionManager.accelerometerUpdateInterval = 0.01
            // Use MainQueue to avoid threading issues with the Detector state
            motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.mainQueue) { data, error ->
                data?.let {
                    it.acceleration.useContents {
                        onUpdate(x, y, z)
                    }
                }
            }
        }
    }

    actual fun stop() {
        motionManager.stopAccelerometerUpdates()
    }
}

actual class SpeechRecognizer {
    private val speechRecognizer = SFSpeechRecognizer(locale = NSLocale(localeIdentifier = "zh-CN"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest? = null
    private var recognitionTask: SFSpeechRecognitionTask? = null
    private val audioEngine = AVAudioEngine()

    actual suspend fun requestPermissions(): Boolean {
        return suspendCancellableCoroutine { cont ->
            SFSpeechRecognizer.requestAuthorization { status: platform.Speech.SFSpeechRecognizerAuthorizationStatus ->
                cont.resume(status == platform.Speech.SFSpeechRecognizerAuthorizationStatus.SFSpeechRecognizerAuthorizationStatusAuthorized) 
            }
        }
    }

    private var isIntentionalStop = false

    actual fun start(onResult: (String, Boolean) -> Unit, onError: (String) -> Unit) {
        if (speechRecognizer?.available == false) {
             onError("Recognizer not available")
             return
        }
        
        isIntentionalStop = false
        
        recognitionTask?.cancel()
        recognitionTask = null
        
        val audioSession = AVAudioSession.sharedInstance()
        try {
            // Also use PlayAndRecord here so we don't break playback
            audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, mode = AVAudioSessionModeVoiceChat, options = 0u, error = null)
            audioSession.setActive(true, error = null) 
        } catch (e: Exception) {
            onError("Audio Session Error")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        val inputNode = audioEngine.inputNode
        
        val request = recognitionRequest ?: return
        request.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTaskWithRequest(request) { result, error ->
            var isFinal = false
            
            if (result != null) {
                val text = result.bestTranscription.formattedString 
                isFinal = result.isFinal() 
                onResult(text, isFinal)
            }
            
            if (error != null || isFinal) {
                audioEngine.stop()
                inputNode.removeTapOnBus(0u)
                
                // Auto-Restart if not intentional stop
                if (!isIntentionalStop) {
                    println("iOS SpeechRecognizer: Restarting...")
                    start(onResult, onError)
                }
            }
        }
        
        val recordingFormat = inputNode.outputFormatForBus(0u)
        inputNode.removeTapOnBus(0u) // Ensure no existing tap
        inputNode.installTapOnBus(0u, bufferSize = 1024u, format = recordingFormat) { buffer, _ ->
            buffer?.let { request.appendAudioPCMBuffer(it) }
        }
        
        audioEngine.prepare()
        try {
            audioEngine.startAndReturnError(null)
        } catch (e: Exception) {
            onError("Audio Engine Start Error")
        }
    }

    actual fun stop() {
        isIntentionalStop = true
        audioEngine.stop()
        if (audioEngine.inputNode.numberOfInputs > 0u) { 
             audioEngine.inputNode.removeTapOnBus(0u)
        }
        
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = null
        recognitionRequest = null
    }
}

actual class ScreenshotDetector {
    private var observer: platform.darwin.NSObjectProtocol? = null

    actual fun start(onScreenshotDetected: () -> Unit) {
        observer = NSNotificationCenter.defaultCenter.addObserverForName(
            name = UIApplicationUserDidTakeScreenshotNotification,
            `object` = null,
            queue = NSOperationQueue.mainQueue
        ) { _ ->
            onScreenshotDetected()
        }
    }

    actual fun stop() {
        observer?.let {
            NSNotificationCenter.defaultCenter.removeObserver(it)
        }
        observer = null
    }
}

actual class AudioRecorder {
    private var recorder: AVAudioRecorder? = null
    private var startTime: Long = 0
    private var _isRecording = false

    actual fun startRecording(filePath: String) {
        val url = NSURL.fileURLWithPath(filePath)

        // Fix: Use raw value if unresolved, or platform.AudioToolbox.kAudioFormatMPEG4AAC 
        // Actually, let's try 1633772320 (0x61616320) which is 'aac '
        val aacFormatId = 1633772320u // 'aac '

        val settingsMap = mapOf<Any?, Any?>(
            platform.AVFAudio.AVFormatIDKey to aacFormatId,
            platform.AVFAudio.AVSampleRateKey to 44100.0,
            platform.AVFAudio.AVNumberOfChannelsKey to 1
        )
        
        try {
            val audioSession = AVAudioSession.sharedInstance()
            audioSession.setCategory(AVAudioSessionCategoryRecord, error = null)
            audioSession.setActive(true, error = null)
            
            // Check constructor: AVAudioRecorder(url, settings, error)
            // error is typically `error = null`
            recorder = AVAudioRecorder(url, settingsMap, null)
            recorder?.prepareToRecord()
            recorder?.record()
            recorder?.record()
            startTime = Clock.System.now().toEpochMilliseconds()
            _isRecording = true
        } catch (e: Exception) {
            println("iOS AudioRecorder Error: $e")
        }
    }

    actual fun stopRecording() {
        recorder?.stop()
        recorder = null
        _isRecording = false
    }

    actual fun isRecording(): Boolean = _isRecording

    actual fun getRecordingDuration(): Long {
        if (!_isRecording) return 0
        return Clock.System.now().toEpochMilliseconds() - startTime
    }
}

actual fun getAppCachePath(): String {
    val paths = platform.Foundation.NSSearchPathForDirectoriesInDomains(
        platform.Foundation.NSCachesDirectory,
        platform.Foundation.NSUserDomainMask,
        true
    )
    return paths.first() as String
}

actual fun readFile(filePath: String): ByteArray {
    val nsData = platform.Foundation.NSData.create(contentsOfFile = filePath)
    if (nsData == null) return ByteArray(0)
    val length = nsData.length.toInt()
    val bytes = ByteArray(length)
    bytes.usePinned { pinned ->
        memcpy(pinned.addressOf(0), nsData.bytes, nsData.length)
    }
    return bytes
}

// iOS Implementation
class FilePickerLauncherImpl(private val onResult: (ByteArray?) -> Unit) : FilePickerLauncher {
    private val delegate = FilePickerDelegate(onResult)
    
    override fun launch() {
        val rootVC = UIApplication.sharedApplication.keyWindow?.rootViewController
        if (rootVC == null) {
            println("FilePicker: Root VC is null")
            return
        }
        
        // Define audio types
        val types = listOf("public.audio", "public.mp3", "public.mpeg-4-audio", "com.apple.m4a-audio")
        val picker = UIDocumentPickerViewController(documentTypes = types, inMode = UIDocumentPickerMode.UIDocumentPickerModeImport)
        picker.delegate = delegate
        rootVC.presentViewController(picker, animated = true, completion = null)
    }
}

class FilePickerDelegate(private val onResult: (ByteArray?) -> Unit) : NSObject(), UIDocumentPickerDelegateProtocol {
    override fun documentPicker(controller: UIDocumentPickerViewController, didPickDocumentsAtURLs: List<*>) {
        val url = didPickDocumentsAtURLs.firstOrNull() as? NSURL
        if (url != null) {
            // Using dataWithContentsOfURL for reading file from URL
            val nsData = NSData.dataWithContentsOfURL(url)
            if (nsData != null) {
                val length = nsData.length.toInt()
                val bytes = ByteArray(length)
                bytes.usePinned { pinned ->
                    memcpy(pinned.addressOf(0), nsData.bytes, nsData.length)
                }
                onResult(bytes)
            } else {
                onResult(null)
            }
        }
    }
    
    override fun documentPickerWasCancelled(controller: UIDocumentPickerViewController) {
        // Do nothing or call onResult(null)
        onResult(null)
    }
}

@androidx.compose.runtime.Composable
actual fun rememberFilePickerLauncher(onResult: (ByteArray?) -> Unit): FilePickerLauncher {
    return androidx.compose.runtime.remember { FilePickerLauncherImpl(onResult) }
}
