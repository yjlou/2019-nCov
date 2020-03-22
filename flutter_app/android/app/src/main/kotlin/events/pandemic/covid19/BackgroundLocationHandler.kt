package events.pandemic.covid19

import android.content.Context
import android.os.Build
import android.util.Log
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.util.concurrent.TimeUnit

class BackgroundLocationHandler : MethodChannel.MethodCallHandler {
    private var engine: FlutterEngine
    private var channel: MethodChannel
    private var context: Context

    companion object {
        private const val CHANNEL_NAME = "events.pandemic.covid19/background_location"
        // There is a 23 character limit for LOG TAG.
        private const val LOG_TAG = "BgHandler"

        @JvmStatic
        fun registerWith(engine: FlutterEngine, context: Context) {
            val channel = MethodChannel(
                    engine.dartExecutor.binaryMessenger,
                    CHANNEL_NAME
            )
            channel.setMethodCallHandler(BackgroundLocationHandler(engine, context, channel))
        }
    }

    constructor(engine: FlutterEngine, context: Context, channel: MethodChannel) {
        this.engine = engine
        this.channel = channel
        this.context = context
    }

    @androidx.annotation.RequiresApi(Build.VERSION_CODES.GINGERBREAD)
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> {
                Log.d(LOG_TAG, "starting!")
                /*
                val workRequest =
                    PeriodicWorkRequestBuilder<BackgroundLocationWorker>(5, TimeUnit.MINUTES).build()
                WorkManager.getInstance(context).enqueue(workRequest)
                          */
            }

            "stop" -> {
                Log.d(LOG_TAG, "stopped!")
            }

            "status" -> {
                Log.d(LOG_TAG, "get status")
            }
        }
    }
}