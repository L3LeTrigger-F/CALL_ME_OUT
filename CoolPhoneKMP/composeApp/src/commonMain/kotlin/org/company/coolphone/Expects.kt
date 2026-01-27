package org.company.coolphone

expect class AudioPlayer() {
    suspend fun play(data: ByteArray)
    fun stop()
    fun playSystemRingtone()
    fun setSpeakerphone(enabled: Boolean)
    fun playFiller() // New: Play subtle sound to mask latency
}

expect class Accelerometer() {
    fun start(onUpdate: (x: Double, y: Double, z: Double) -> Unit)
    fun stop()
}

expect class SpeechRecognizer() {
    fun start(onResult: (String, Boolean) -> Unit, onError: (String) -> Unit)
    fun stop()
    suspend fun requestPermissions(): Boolean
}

expect class ScreenshotDetector() {
    fun start(onScreenshotDetected: () -> Unit)
    fun stop()
}

expect class AudioRecorder() {
    fun startRecording(filePath: String)
    fun stopRecording()
    fun isRecording(): Boolean
    fun getRecordingDuration(): Long
}

expect fun getAppCachePath(): String
expect fun readFile(filePath: String): ByteArray

interface FilePickerLauncher {
    fun launch()
}

@androidx.compose.runtime.Composable
expect fun rememberFilePickerLauncher(onResult: (ByteArray?) -> Unit): FilePickerLauncher
