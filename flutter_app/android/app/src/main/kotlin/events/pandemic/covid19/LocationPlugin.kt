package events.pandemic.covid19

import android.content.Context
import android.location.Location
import android.os.Build
import android.os.Looper
import android.util.Log
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import be.tramckrijte.workmanager.BackgroundWorker
import be.tramckrijte.workmanager.SharedPreferenceHelper
import com.google.android.gms.location.*
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.shim.ShimPluginRegistry
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import io.flutter.view.FlutterCallbackInformation
import io.flutter.view.FlutterMain
import org.json.JSONObject
import java.util.concurrent.TimeUnit

class LocationPlugin : FlutterPlugin {
    companion object {
        private const val CHANNEL_NAME = "events.pandemic.covid19/location_plugin"

        // There is a 23 character limit for LOG TAG.
        const val LOG_TAG = "BgHandler"

        // var pluginRegistryCallback: PluginRegistry.PluginRegistrantCallback? = null

        @JvmStatic
        fun registerWith(registrar: PluginRegistry.Registrar) = registerWithImpl(
                registrar.messenger(), registrar.activeContext())

        @JvmStatic
        fun registerWithImpl(messenger: BinaryMessenger, context: Context) {
            Log.d(LOG_TAG, "register!!!")
            val channel = MethodChannel(
                    messenger,
                    CHANNEL_NAME
            )

            channel.setMethodCallHandler(LocationPluginHandler(context, messenger))
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        registerWithImpl(binding.binaryMessenger, binding.applicationContext)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // pass
    }
}

class LocationPluginHandler(private var context: Context, private var messenger: BinaryMessenger) : MethodChannel.MethodCallHandler {
    companion object {
        private val LOG_TAG = "LocationPluginHandler"
    }

    private var client: FusedLocationProviderClient
    private var locationCallback: LocationCallback
    private var locationRequest: LocationRequest
    private var cachedLocations = ArrayList<Location>()
    private var getLocationRequestResult: MethodChannel.Result? = null
//    private var flutterEngine: FlutterEngine

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
//                for (location in result.locations) {
//                    cachedLocations.add(location)
//                }

                if (getLocationRequestResult != null) {
                    val location = result.lastLocation
                    val retval = HashMap<String, Double>()
                    retval["latitude"] = location.latitude
                    retval["longitude"] = location.longitude
                    retval["altitude"] = location.altitude
                    retval["accuracy"] = location.accuracy.toDouble()
                    retval["speed"] = location.speed.toDouble()
                    retval["time"] = location.time.toDouble()

                    // retval[""]

                    invokeGetLocationCallback(retval)
                    // getLocationRequestResult!!.success(retval)
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
//        Hopefully, this is already done by BackgroundWorker
//        val flutterEngine = FlutterEngine(context)
//        FlutterMain.ensureInitializationComplete(context, null)
//        val callbackHandle = SharedPreferenceHelper.getCallbackHandle(context)
//        val callbackInfo = FlutterCallbackInformation.lookupCallbackInformation(callbackHandle)
//        val dartBundlePath = FlutterMain.findAppBundlePath()
//
//        LocationPlugin.pluginRegistryCallback?.registerWith(ShimPluginRegistry(flutterEngine))
//        flutterEngine.dartExecutor.executeDartCallback(DartExecutor.DartCallback(
//                context.assets, dartBundlePath, callbackInfo))
//
//        val dartTaskKey = BackgroundWorker.DART_TASK_KEY
//        val payloadKey = BackgroundWorker.PAYLOAD_KEY
//        val channel = MethodChannel(messenger, BackgroundWorker.BACKGROUND_CHANNEL_NAME)
//
//        channel.setMethodCallHandler { call, result ->
//            when (call.method) {
//                BackgroundWorker.BACKGROUND_CHANNEL_INITIALIZED -> {
//                    channel.invokeMethod(
//                            "onResultSend",
//                            mapOf(
//                                    dartTaskKey to "get_location_callback",
//                                    payloadKey to JSONObject(location).toString()
//                            ),
//                            object: MethodChannel.Result {
//                                override fun notImplemented() {
//                                    Log.d(LOG_TAG, "get_location_callback: not implemented")
//                                }
//
//                                override fun error(errorCode: String?, errorMessage: String?, errorDetails: Any?) {
//                                    Log.d(LOG_TAG, "get_location_callback: ${errorCode} ${errorMessage} ${errorDetails}")
//                                }
//
//                                override fun success(result: Any?) {
//                                    Log.d(LOG_TAG, "get_location_callback: ${result}")
//                                }
//
//                            }
//                    )
//                }
//            }
//        }

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