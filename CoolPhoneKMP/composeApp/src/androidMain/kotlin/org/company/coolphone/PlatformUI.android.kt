package org.company.coolphone

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.CallEnd
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.MicOff
import androidx.compose.material.icons.filled.VolumeUp
import androidx.compose.material.icons.filled.Dialpad
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Videocam
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

@Composable
actual fun IncomingCallScreen(
    contact: Contact,
    onAccept: () -> Unit,
    onDecline: () -> Unit
) {
    // Pulse Animation for Avatar
    val infiniteTransition = rememberInfiniteTransition()
    val pulseScale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.2f,
        animationSpec = infiniteRepeatable(
            animation = tween(1000),
            repeatMode = RepeatMode.Reverse
        )
    )

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    colors = listOf(
                        Color(0xFF0F2027), 
                        Color(0xFF203A43), 
                        Color(0xFF2C5364)
                    )
                )
            )
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(vertical = 60.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            
            // Top Section: Caller Info
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.padding(top = 40.dp)
            ) {
                // Avatar with Pulse
                Box(contentAlignment = Alignment.Center) {
                    Box(
                        modifier = Modifier
                            .size(150.dp)
                            .scale(pulseScale)
                            .background(Color.White.copy(alpha = 0.2f), CircleShape)
                    )
                    Box(
                        modifier = Modifier
                            .size(120.dp)
                            .clip(CircleShape)
                            .background(Color(0xFFE0E0E0), CircleShape),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = contact.name.take(1),
                            fontSize = 48.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color(0xFF2C5364)
                        )
                    }
                }
                
                Spacer(modifier = Modifier.height(32.dp))
                
                Text(
                    text = contact.name,
                    color = Color.White,
                    fontSize = 36.sp,
                    fontWeight = FontWeight.SemiBold,
                    letterSpacing = 1.sp
                )
                
                Spacer(modifier = Modifier.height(8.dp))
                
                Text(
                    text = "${contact.relation} | ${contact.number}",
                    color = Color.White.copy(alpha = 0.7f),
                    fontSize = 16.sp
                )
            }
            
            // Bottom Section: Actions
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 40.dp, vertical = 40.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Decline Column
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    FloatingActionButton(
                        onClick = onDecline,
                        backgroundColor = Color(0xFFFF4B4B), // Custom Red
                        contentColor = Color.White,
                        modifier = Modifier
                            .size(72.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Filled.CallEnd,
                            contentDescription = "Decline",
                            modifier = Modifier.size(32.dp)
                        )
                    }
                    Spacer(modifier = Modifier.height(12.dp))
                    Text(
                        "Decline",
                        color = Color.White.copy(alpha = 0.8f),
                        fontSize = 14.sp
                    )
                }
                
                // Accept Column
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    FloatingActionButton(
                        onClick = onAccept,
                        backgroundColor = Color(0xFF4CAF50), // Custom Green
                        contentColor = Color.White,
                        modifier = Modifier
                            .size(72.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Filled.Call,
                            contentDescription = "Accept",
                            modifier = Modifier.size(32.dp)
                        )
                    }
                    Spacer(modifier = Modifier.height(12.dp))
                    Text(
                        "Accept",
                        color = Color.White.copy(alpha = 0.8f),
                        fontSize = 14.sp
                    )
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
    val service = AICallManager
    val isProcessing by service.isProcessing.collectAsState()
    
    var durationSeconds by remember { mutableStateOf(0L) }
    var isMuted by remember { mutableStateOf(false) }
    var isSpeakerOn by remember { mutableStateOf(false) }
    
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
                    colors = listOf(
                        Color(0xFF141E30),
                        Color(0xFF243B55)
                    )
                )
            )
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(top = 60.dp, bottom = 40.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            
            // 1. Caller Info Header (Name & Time)
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
                    color = Color.White.copy(alpha = 0.8f),
                    fontSize = 18.sp,
                    letterSpacing = 1.sp
                )
            }
            
            // 2. Central Area (Avatar)
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth(),
                contentAlignment = Alignment.Center
            ) {
                 Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Box(
                        modifier = Modifier
                            .size(160.dp)
                            .background(Color.White.copy(alpha = 0.1f), CircleShape),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = contact.name.take(1),
                            fontSize = 64.sp,
                            color = Color.White.copy(alpha = 0.8f)
                        )
                    }
                }
            }
            
            // 3. Control Panel (Grid Layout)
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 40.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                
                // Top Row Controls
                Row(
                    modifier = Modifier.fillMaxWidth().padding(bottom = 24.dp),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    CallControlButton(
                        icon = if (isMuted) Icons.Filled.MicOff else Icons.Filled.Mic,
                        label = "Mute",
                        isActive = isMuted,
                        onClick = { isMuted = !isMuted }
                    )
                    CallControlButton(
                        icon = Icons.Filled.Dialpad,
                        label = "Keypad",
                        onClick = {}
                    )
                    CallControlButton(
                        icon = Icons.Filled.VolumeUp,
                        label = "Speaker",
                        isActive = isSpeakerOn,
                        onClick = { 
                             isSpeakerOn = !isSpeakerOn 
                             AICallManager.setSpeaker(isSpeakerOn)
                        }
                    )
                }
                
                // Bottom Row Controls (Visual placeholders)
                Row(
                    modifier = Modifier.fillMaxWidth().padding(bottom = 40.dp),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    CallControlButton(
                        icon = Icons.Filled.Add,
                        label = "Add call",
                        onClick = {}
                    )
                    CallControlButton(
                        icon = Icons.Filled.Videocam,
                        label = "Video",
                        onClick = {}
                    )
                     // Using VolumeUp as placeholder for Contacts or similar
                     CallControlButton(
                        icon = Icons.Filled.VolumeUp, 
                        label = "Contacts",
                        isActive = false,
                        onClick = {}
                    )
                }
                
                // End Call Button
                FloatingActionButton(
                    onClick = onEndCall,
                    backgroundColor = Color(0xFFFF4B4B),
                    contentColor = Color.White,
                    modifier = Modifier.size(72.dp)
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
}

@Composable
fun CallControlButton(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    isActive: Boolean = false,
    onClick: () -> Unit
) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        val buttonColor = if (isActive) Color.White else Color.White.copy(alpha = 0.2f)
        val iconColor = if (isActive) Color.Black else Color.White
        
        Button(
            onClick = onClick,
            modifier = Modifier.size(72.dp),
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
                modifier = Modifier.size(32.dp)
            )
        }
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = label,
            color = Color.White.copy(alpha = 0.8f),
            fontSize = 12.sp
        )
    }
}
