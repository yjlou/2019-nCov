package events.pandemic.covid19

import android.content.Context
import android.os.Build
import android.os.Looper
import android.util.Log
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import be.tramckrijte.workmanager.BackgroundWorker
import com.google.android.gms.location.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import org.json.JSONObject
import java.util.concurrent.TimeUnit

class LocationPlugin : FlutterPlugin {
    companion object {
        private const val CHANNEL_NAME = "events.pandemic.covid19/location_plugin"

        // There is a 23 character limit for LOG TAG.
        private const val LOG_TAG = "BgHandler"

        @JvmStatic
        fun registerWith(registrar: PluginRegistry.Registrar) {
            val instance = LocationPlugin()
            instance.onAttachedToEngine(registrar.messenger(), registrar.activeContext())
        }
    }

    private var channel: MethodChannel? = null
    private var handler: LocationPluginHandler? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        onAttachedToEngine(binding.binaryMessenger, binding.applicationContext)
    }

    private fun onAttachedToEngine(messenger: BinaryMessenger, context: Context) {
        Log.d(LOG_TAG, "attached to engine")
        channel = MethodChannel(messenger, CHANNEL_NAME)
        handler = LocationPluginHandler(context)
        channel!!.setMethodCallHandler(handler)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(LOG_TAG, "detached from engine")
        channel?.setMethodCallHandler(null)
        channel = null
        handler = null
    }
}

class LocationPluginHandler(private var context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        private val LOG_TAG = "LocationPluginHandler"
    }

    private var client: FusedLocationProviderClient
    private var locationCallback: LocationCallback
    private var locationRequest: LocationRequest
    private var getLocationRequestResult: MethodChannel.Result? = null

    init {
        Log.d(LOG_TAG, "initialized")

        client = LocationServices.getFusedLocationProviderClient(context)
        locationRequest = LocationRequest()
        locationRequest.interval = 10000
        locationRequest.fastestInterval = 5000

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult?) {
                super.onLocationResult(result)

                result ?: return

                if (getLocationRequestResult != null) {
                    val location = result.lastLocation
                    val retval = HashMap<String, Double>()
                    retval["latitude"] = location.latitude
                    retval["longitude"] = location.longitude
                    retval["altitude"] = location.altitude
                    retval["accuracy"] = location.accuracy.toDouble()
                    retval["speed"] = location.speed.toDouble()
                    retval["time"] = location.time.toDouble()

                    invokeGetLocationCallback(retval)
                    getLocationRequestResult = null
                }

                client.removeLocationUpdates(this)
            }
        }
    }

    private fun invokeGetLocationCallback(location: Map<String, Double>) {
        Log.d(LOG_TAG, "add callback task")
        val workRequest = OneTimeWorkRequestBuilder<BackgroundWorker>()
                .setInputData(buildInputData(location))
                .setInitialDelay(0, TimeUnit.SECONDS)
                .build()
        WorkManager.getInstance(context).enqueueUniqueWork(
                "events.pandemic.covid19/get_location_callback",
                ExistingWorkPolicy.REPLACE,
                workRequest)
    }

    private fun buildInputData(location: Map<String, Double>): Data {
        return Data.Builder()
                .putString(BackgroundWorker.DART_TASK_KEY, "events.pandemic.covid19/get_location_callback")
                .putString(BackgroundWorker.PAYLOAD_KEY, JSONObject(location).toString())
                .build()
    }

    private fun startRequestingLocation() {
        Looper.myLooper() ?: Looper.prepare()
        client.requestLocationUpdates(locationRequest, locationCallback, Looper.myLooper())
    }

    private fun getLocation(result: MethodChannel.Result) {
        getLocationRequestResult = result
        startRequestingLocation()
    }

    @androidx.annotation.RequiresApi(Build.VERSION_CODES.GINGERBREAD)
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "get_location" -> {
                Log.d(LOG_TAG, "get_location called")
                getLocation(result)
            }

            else -> {
                result.notImplemented()
            }
        }
    }
}