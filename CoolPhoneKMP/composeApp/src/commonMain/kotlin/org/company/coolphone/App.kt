package org.company.coolphone

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ExitToApp
import androidx.compose.material.icons.filled.Face
import androidx.compose.material.icons.filled.Phone
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch

enum class AppCallState {
    Idle, Incoming, Active
}

@Composable
fun App() {
    MaterialTheme {
        var callState by remember { mutableStateOf(AppCallState.Idle) }
        var settings by remember { mutableStateOf(CallSettings()) }
        var showSettings by remember { mutableStateOf(false) }
        
        // Back Tap Detector
        val backTapDetector = remember { BackTapDetector() }
        val shouldTrigger by backTapDetector.shouldTriggerCall.collectAsState()
        val globalTrigger by AICallManager.shouldTriggerIncomingCall.collectAsState()
        
        val scope = rememberCoroutineScope()
        val audioPlayer = remember { AudioPlayer() }
        val screenshotDetector = remember { ScreenshotDetector() }
        
        DisposableEffect(Unit) {
            backTapDetector.start()
            screenshotDetector.start {
                // On Screenshot Captured
                if (callState == AppCallState.Idle) {
                    callState = AppCallState.Incoming
                }
            }
            onDispose { 
                 backTapDetector.stop()
                 screenshotDetector.stop()
                 audioPlayer.stop() 
            }
        }
        
        LaunchedEffect(callState) {
            if (callState == AppCallState.Incoming) {
                audioPlayer.playSystemRingtone()
            } else {
                audioPlayer.stop()
            }
        }
        
        // Instant Launch Check
        LaunchedEffect(Unit) {
            if (AICallManager.hasPendingInstantCall) {
                println("🚀 Instant Launch Detected in Compose!")
                AICallManager.hasPendingInstantCall = false
                callState = AppCallState.Incoming
            }
        }
        
        LaunchedEffect(shouldTrigger) {
            if (shouldTrigger && callState == AppCallState.Idle) {
                // Back Tap triggers a delayed call (e.g. 3 seconds) for realism
                 AICallManager.scheduleIncomingCall(3000)
            }
        }
        
        LaunchedEffect(globalTrigger) {
             if (globalTrigger && callState == AppCallState.Idle) {
                 callState = AppCallState.Incoming
                 AICallManager.shouldTriggerIncomingCall.value = false
             }
        }

        Box(modifier = Modifier.fillMaxSize()) {
            when {
                showSettings -> {
                    SettingsScreen(
                        currentSettings = settings,
                        onSave = { 
                            settings = it
                            showSettings = false 
                        },
                        onBack = { showSettings = false }
                    )
                }
                callState == AppCallState.Incoming -> {
                    IncomingCallScreen(
                        contact = Contact(
                            name = settings.callerName,
                            number = settings.callerNumber,
                            avatar = settings.callerAvatar,
                            relation = settings.callerRelation,
                            color = 0
                        ),
                        onAccept = {
                            callState = AppCallState.Active
                            AICallManager.startCall(
                                settings.scenario, 
                                settings.customScenarioText,
                                settings.customVoiceId
                            )
                        },
                        onDecline = {
                            callState = AppCallState.Idle
                            AICallManager.endCall()
                        }
                    )
                }
                callState == AppCallState.Active -> {
                    CallInProgressScreen(
                        contact = Contact(
                            name = settings.callerName,
                            number = settings.callerNumber,
                            avatar = settings.callerAvatar,
                            relation = settings.callerRelation,
                            color = 0
                        ),
                        onEndCall = {
                            callState = AppCallState.Idle
                            AICallManager.endCall()
                        }
                    )
                }
                else -> {
                    // New Home Screen UI
                    HomeScreen(
                        onOpenSettings = { showSettings = true },
                        onSimulateCall = { 
                            if (settings.delaySeconds > 0) {
                                AICallManager.scheduleIncomingCall(settings.delaySeconds * 1000L)
                            } else {
                                callState = AppCallState.Incoming 
                            }
                        }
                    )
                }
            }
        }
    }
}

@Composable
fun HomeScreen(
    onOpenSettings: () -> Unit,
    onSimulateCall: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFFE0F7FA)) // Light Cyan Background
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            // 1. App Icon / Logo
            Box(
                modifier = Modifier
                    .size(100.dp)
                    .clip(RoundedCornerShape(24.dp))
                    .background(
                        Brush.linearGradient(
                            colors = listOf(Color(0xFF4DD0E1), Color(0xFF00bcd4))
                        )
                    ),
                contentAlignment = Alignment.Center
            ) {
                 Icon(
                     imageVector = Icons.Filled.ExitToApp, // Walking out icon equivalent
                     contentDescription = "Logo",
                     tint = Color.White,
                     modifier = Modifier.size(60.dp)
                 )
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // 2. Title and Subtitle
            Text(
                text = "Call Me Out",
                color = Color(0xFF457B9D),
                fontSize = 36.sp,
                fontWeight = FontWeight.Bold,
                letterSpacing = 1.sp
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "一个安全有效的社交逃离通道",
                color = Color(0xFF607D8B),
                fontSize = 16.sp,
                fontWeight = FontWeight.Medium
            )
            
            Spacer(modifier = Modifier.height(48.dp))
            
            // 3. Feature Cards
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                FeatureCard(
                    icon = Icons.Filled.Phone,
                    title = "虚拟来电",
                    subtitle = "逼真的来电界面",
                    color = Color(0xFF2196F3),
                    modifier = Modifier.weight(1f)
                )
                FeatureCard(
                    icon = Icons.Filled.Face,
                    title = "AI对话",
                    subtitle = "智能剧本对话",
                    color = Color(0xFF9C27B0),
                    modifier = Modifier.weight(1f)
                )
            }
            
            Spacer(modifier = Modifier.height(64.dp))
            
            // 4. Action Buttons
            GradientButton(
                text = "设置来电剧本",
                gradient = Brush.horizontalGradient(
                    colors = listOf(Color(0xFF64B5F6), Color(0xFF7986CB))
                ),
                onClick = onOpenSettings
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            GradientButton(
                text = "模拟来电测试",
                gradient = Brush.horizontalGradient(
                    colors = listOf(Color(0xFFBA68C8), Color(0xFFF06292)) // Purple/Pink
                ),
                onClick = onSimulateCall
            )
        }
    }
}

@Composable
fun FeatureCard(
    icon: ImageVector,
    title: String,
    subtitle: String,
    color: Color,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.height(140.dp),
        shape = RoundedCornerShape(20.dp),
        elevation = 4.dp,
        backgroundColor = Color.White
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.Top,
            horizontalAlignment = Alignment.Start
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = color,
                modifier = Modifier.size(32.dp)
            )
            Spacer(modifier = Modifier.weight(1f))
            Text(
                text = title,
                fontWeight = FontWeight.Bold,
                fontSize = 18.sp,
                color = Color.Black
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = subtitle,
                fontSize = 12.sp,
                color = Color.Gray
            )
        }
    }
}

@Composable
fun GradientButton(
    text: String,
    gradient: Brush,
    onClick: () -> Unit
) {
    Button(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .height(56.dp)
            .clip(RoundedCornerShape(16.dp)),
        colors = ButtonDefaults.buttonColors(backgroundColor = Color.Transparent),
        contentPadding = PaddingValues(0.dp)
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(gradient),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = text,
                color = Color.White,
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold
            )
        }
    }
}
