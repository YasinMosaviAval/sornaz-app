package com.example.sornaz

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel

/** Reports internet-capable network changes; HTTP still validates server reachability. */
class PracticeNetwork(context: Context, messenger: BinaryMessenger) : EventChannel.StreamHandler {
    private val manager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    private val channel = EventChannel(messenger, "sornaz/network")
    private val handler = Handler(Looper.getMainLooper())
    private var sink: EventChannel.EventSink? = null
    private var registered = false
    private val onlineNetworks = mutableSetOf<Network>()
    private var lastOnline: Boolean? = null
    private val callback = object : ConnectivityManager.NetworkCallback() {
        override fun onAvailable(network: Network) = update(network, true)
        override fun onLost(network: Network) = update(network, false)
        override fun onCapabilitiesChanged(network: Network, capabilities: NetworkCapabilities) {
            update(network, capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET))
        }
    }
    init { channel.setStreamHandler(this) }
    private fun update(network: Network, available: Boolean) { handler.post {
        if (sink == null) return@post
        if (available) onlineNetworks.add(network) else onlineNetworks.remove(network)
        val online = onlineNetworks.isNotEmpty()
        if (lastOnline != online) { lastOnline = online; sink?.success(online) }
    } }
    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        sink = events
        onlineNetworks.clear()
        lastOnline = null
        if (!registered) {
            try {
                manager.registerNetworkCallback(NetworkRequest.Builder().addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET).build(), callback)
                registered = true
            } catch (_: Exception) { events.error("NETWORK_UNAVAILABLE", "Network notifications unavailable", null) }
        }
    }
    override fun onCancel(arguments: Any?) {
        sink = null
        onlineNetworks.clear()
        lastOnline = null
        if (registered) { manager.unregisterNetworkCallback(callback); registered = false }
    }
    fun dispose() { onCancel(null); channel.setStreamHandler(null) }
}
