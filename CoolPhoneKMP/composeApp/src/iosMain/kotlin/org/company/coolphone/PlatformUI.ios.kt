package org.company.coolphone

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import kotlinx.datetime.Clock

// iOS Colors
val IOS_Background_Top = Color(0xFF1C1C1E) // iOS Dark specific
val IOS_Background_Bottom = Color(0xFF000000) // Black
val IOS_Green = Color(0xFF34C759)
val IOS_Red = Color(0xFFFF3B30)
val IOS_Grey_Button = Color(0xFFFFFF).copy(alpha = 0.2f) // Glassmorphism style
val IOS_Text_Grey = Color(0xFF8E8E93)

@Composable
actual fun IncomingCallScreen(
    contact: Contact,
    onAccept: () -> Unit,
    onDecline: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    colors = listOf(IOS_Background_Top, IOS_Background_Bottom)
                )
            )
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(top = 80.dp, bottom = 60.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            
            // 1. Caller Info
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    text = "移动电话",
                    color = IOS_Text_Grey,
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Normal
                )
                Spacer(modifier = Modifier.height(16.dp))
                Text(
                    text = contact.name,
                    color = Color.White,
                    fontSize = 42.sp,
                    fontWeight = FontWeight.Medium,
                    letterSpacing = 0.5.sp
                )
            }
            
            // 2. Middle Options usually (Remind Me, Message) - Placeholder
            // Leaving empty for clean look or could add icons
            
            // 3. Action Buttons
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 40.dp)
            ) {
                // Secondary Options
                Row(
                    modifier = Modifier.fillMaxWidth().padding(bottom = 30.dp), // Reduced spacing
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                   IOSSecondaryButton(icon = Icons.Filled.Message, label = "信息") // Swaped: Message Left
                   IOSSecondaryButton(icon = Icons.Filled.Alarm, label = "提醒我") // Swaped: Remind Right (or match image)
                }
                
                // Answer/Decline
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Decline
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        FloatingActionButton(
                            onClick = onDecline,
                            backgroundColor = IOS_Red,
                            contentColor = Color.White,
                            modifier = Modifier.size(75.dp),
                            elevation = FloatingActionButtonDefaults.elevation(0.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Filled.CallEnd,
                                contentDescription = "Decline",
                                modifier = Modifier.size(35.dp)
                            )
                        }
                        Spacer(modifier = Modifier.height(12.dp))
                        Spacer(modifier = Modifier.height(12.dp))
                        Text("拒绝", color = Color.White, fontSize = 16.sp)
                    }
                    
                    // Accept
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        FloatingActionButton(
                            onClick = onAccept,
                            backgroundColor = IOS_Green,
                            contentColor = Color.White,
                            modifier = Modifier.size(75.dp),
                            elevation = FloatingActionButtonDefaults.elevation(0.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Filled.Call,
                                contentDescription = "Accept",
                                modifier = Modifier.size(35.dp)
                            )
                        }
                        Spacer(modifier = Modifier.height(12.dp))
                        Text("接听", color = Color.White, fontSize = 16.sp)
                    }
                }
            }
        }
    }
}

@Composable
actual fun CallInProgressScreen(
    contact: Contact,
    onEndCall: () -> Unit
) {
    // Timer Logic
    var durationSeconds by remember { mutableStateOf(0L) }
    var isMuted by remember { mutableStateOf(false) }
    var isSpeakerOn by remember { mutableStateOf(false) }
    var isKeypadVisible by remember { mutableStateOf(false) }
    
    LaunchedEffect(Unit) {
        val startTime = Clock.System.now().toEpochMilliseconds()
        while(true) {
            delay(1000)
            durationSeconds = (Clock.System.now().toEpochMilliseconds() - startTime) / 1000
        }
    }
    
    val minutes = durationSeconds / 60
    val seconds = durationSeconds % 60
    val timeString = "${if (minutes < 10) "0$minutes" else minutes}:${if (seconds < 10) "0$seconds" else seconds}"

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    colors = listOf(IOS_Background_Top, IOS_Background_Bottom)
                )
            )
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(top = 60.dp, bottom = 50.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            
            // 1. Caller Info
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    text = contact.name,
                    color = Color.White,
                    fontSize = 36.sp,
                    fontWeight = FontWeight.Medium
                )
                Spacer(modifier = Modifier.height(12.dp))
                Text(
                    text = timeString,
                    color = Color.White,
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Normal
                )
            }
            
            // 2. Control Grid (6 Buttons)
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 40.dp),
                verticalArrangement = Arrangement.spacedBy(24.dp)
            ) {
                // Grid pushed to bottom
                Spacer(modifier = Modifier.weight(1f))
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    IOSControlButton(
                        icon = Icons.Filled.VolumeUp,
                        label = "免提", 
                        isActive = isSpeakerOn,
                        onClick = { 
                            isSpeakerOn = !isSpeakerOn
                            AICallManager.setSpeaker(isSpeakerOn)
                        }
                    )
                    IOSControlButton(
                        icon = Icons.Filled.Videocam,
                        label = "FaceTime通话",
                        onClick = {}
                    )
                    IOSControlButton(
                        icon = if(isMuted) Icons.Filled.MicOff else Icons.Filled.Mic,
                        label = "静音",
                        isActive = isMuted,
                        onClick = { isMuted = !isMuted }
                    )
                }
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    IOSControlButton(
                        icon = Icons.Filled.MoreHoriz,
                        label = "更多",
                        onClick = {}
                    )
                    // End Call (Red Button in Grid)
                    IOSControlButton(
                        icon = Icons.Filled.CallEnd,
                        label = "结束",
                        isActive = true, // Force white text/icon style logic if needed, but we override color
                        onClick = onEndCall,
                        customBackgroundColor = IOS_Red,
                        customContentColor = Color.White
                    )
                    IOSControlButton(
                        icon = Icons.Filled.Dialpad,
                        label = "拨号键盘",
                        isActive = isKeypadVisible,
                        onClick = { isKeypadVisible = !isKeypadVisible }
                    )
                }
            }
            

            
            Spacer(modifier = Modifier.height(50.dp))
            
            // 3. End Call Button
            FloatingActionButton(
                onClick = onEndCall,
                backgroundColor = IOS_Red,
                contentColor = Color.White,
                modifier = Modifier.size(72.dp),
                elevation = FloatingActionButtonDefaults.elevation(0.dp)
            ) {
                Icon(
                    imageVector = Icons.Filled.CallEnd,
                    contentDescription = "End Call",
                    modifier = Modifier.size(32.dp)
                )
            }
        }
    }
}


@Composable
fun IOSControlButton(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    isActive: Boolean = false,
    customBackgroundColor: Color? = null,
    customContentColor: Color? = null,
    onClick: () -> Unit
) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        val buttonColor = customBackgroundColor ?: if (isActive) Color.White else IOS_Grey_Button
        val iconColor = customContentColor ?: if (isActive) Color.Black else Color.White
        
        Button(
            onClick = onClick,
            modifier = Modifier.size(75.dp),
            shape = CircleShape,
            colors = ButtonDefaults.buttonColors(
                backgroundColor = buttonColor,
                contentColor = iconColor
            ),
            elevation = ButtonDefaults.elevation(0.dp)
        ) {
            Icon(
                imageVector = icon,
                contentDescription = label,
                modifier = Modifier.size(35.dp)
            )
        }
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = label,
            color = Color.White,
            fontSize = 13.sp
        )
    }
}

@Composable
fun IOSSecondaryButton(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String
) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Icon(
            imageVector = icon,
            contentDescription = label,
            tint = Color.White,
            modifier = Modifier.size(28.dp)
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = label,
            color = Color.White,
            fontSize = 13.sp
        )
    }
}
