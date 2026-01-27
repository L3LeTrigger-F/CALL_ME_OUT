package org.company.coolphone

import androidx.compose.runtime.Composable

@Composable
expect fun IncomingCallScreen(
    contact: Contact,
    onAccept: () -> Unit,
    onDecline: () -> Unit
)

@Composable
expect fun CallInProgressScreen(
    contact: Contact,
    onEndCall: () -> Unit
)
