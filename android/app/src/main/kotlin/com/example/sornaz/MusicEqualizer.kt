package com.example.sornaz

import android.media.audiofx.DynamicsProcessing
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import kotlin.math.sqrt

/** Session-scoped equalization: never attaches to the device-wide output. */
class MusicEqualizer(messenger: BinaryMessenger) {
    private var effect: DynamicsProcessing? = null
    private var session = 0
    private var count = 0

    init {
        MethodChannel(messenger, "sornaz/music_equalizer").setMethodCallHandler { call, result ->
            if (call.method == "release") {
                release()
                result.success(null)
            } else if (call.method != "apply") {
                result.notImplemented()
            } else if (Build.VERSION.SDK_INT < 28) {
                result.error("UNSUPPORTED", "This equalizer requires Android 9 or later.", null)
            } else {
                try {
                    val id = call.argument<Number>("session")!!.toInt()
                    val frequencies = call.argument<List<Number>>("frequencies")!!.map { it.toFloat() }
                    val gains = call.argument<List<Number>>("gains")!!.map { it.toFloat() }
                    require(id > 0 && frequencies.size in listOf(5, 10) && frequencies.size == gains.size)
                    require(gains.all { it.isFinite() && it in -15f..15f })
                    require(frequencies.all { it.isFinite() && it > 0f } && frequencies.zipWithNext().all { it.first < it.second })
                    val eq = DynamicsProcessing.Eq(true, true, gains.size)
                    for (i in gains.indices) {
                        // Android expects upper band boundaries, not center frequencies.
                        val cutoff = if (i == gains.lastIndex) 24000f else sqrt(frequencies[i] * frequencies[i + 1])
                        eq.setBand(i, DynamicsProcessing.EqBand(true, cutoff, gains[i]))
                    }
                    if (effect == null || session != id || count != gains.size) {
                        release()
                        val config = DynamicsProcessing.Config.Builder(
                            DynamicsProcessing.VARIANT_FAVOR_FREQUENCY_RESOLUTION,
                            2, true, gains.size, false, 0, false, 0, false
                        ).setPreEqAllChannelsTo(eq).build()
                        effect = DynamicsProcessing(0, id, config)
                        session = id
                        count = gains.size
                    } else {
                        effect!!.setPreEqAllChannelsTo(eq)
                    }
                    effect!!.enabled = call.argument<Boolean>("enabled") == true
                    result.success(null)
                } catch (error: Exception) {
                    release()
                    result.error("EQUALIZER_FAILED", error.message, null)
                }
            }
        }
    }

    fun release() {
        if (Build.VERSION.SDK_INT >= 28) effect?.release()
        effect = null
        session = 0
        count = 0
    }
}
