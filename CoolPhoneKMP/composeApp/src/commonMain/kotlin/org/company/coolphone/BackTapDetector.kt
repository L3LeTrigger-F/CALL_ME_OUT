package org.company.coolphone

import kotlinx.datetime.Clock
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.delay
import kotlin.math.pow
import kotlin.math.sqrt

class BackTapDetector {
    private val accelerometer = Accelerometer()
    
    private val _shouldTriggerCall = MutableStateFlow(false)
    val shouldTriggerCall = _shouldTriggerCall.asStateFlow()
    
    // Config
    private val tapThreshold = 0.15 // Very sensitive
    private val tapTimeWindow = 600L 
    private val cooldownTime = 1000L 
    
    // State
    private var lastTapTime: Long = 0
    private var tapCount = 0
    private var lastTriggerTime: Long = 0
    private var lastZ: Double = 0.0

    
    fun start() {
        accelerometer.start { x, y, z ->
            processData(x, y, z)
        }
    }
    
    fun stop() {
        accelerometer.stop()
    }
    
    private fun processData(x: Double, y: Double, z: Double) {
        // High-pass filter for Z-axis primarily (Back Tap acts on Z)
        val deltaZ = kotlin.math.abs(z - lastZ)
        lastZ = z
        
        // Removed magnitude check to allow detection in more orientations/conditions
        // Detect sudden change in Z (Jolt)
        if (deltaZ > tapThreshold) { 
            detectTap()
        }
    }
    
    private fun detectTap() {
        val now = Clock.System.now().toEpochMilliseconds()
        
        // Cooldown
        if (now - lastTriggerTime < cooldownTime) {
            return
        }
        
        // Window check
        if (now - lastTapTime < tapTimeWindow) {
            tapCount++
            println("📍 Detect tap $tapCount")
            
            if (tapCount == 2) {
                triggerCall()
                resetTapDetection()
            }
        } else {
            // Reset / First tap
            lastTapTime = now
            tapCount = 1
            println("📍 First tap")
        }
    }
    
    private fun triggerCall() {
        println("🎉 Trigger Call!")
        MainScope().launch {
            _shouldTriggerCall.value = true
            lastTriggerTime = Clock.System.now().toEpochMilliseconds()
            delay(200)
            _shouldTriggerCall.value = false
        }
    }
    
    private fun resetTapDetection() {
        lastTapTime = 0
        tapCount = 0
    }
}
