package events.pandemic.plugins.location_collector

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
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.util.concurrent.ExecutionException
import java.util.concurrent.TimeUnit

class LocationPluginHandler(private var context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        private val LOG_TAG = "LocationPluginHandler"
        val WORK_TAG = "events.pandemic.plugins.location_collector/get_location_callback"
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
                    val result = HashMap<String, Double>()
                    result["latitude"] = location.latitude
                    result["longitude"] = location.longitude
                    result["altitude"] = location.altitude
                    result["accuracy"] = location.accuracy.toDouble()
                    result["speed"] = location.speed.toDouble()
                    result["time"] = location.time.toDouble()

                    invokeGetLocationCallback(result)
                    getLocationRequestResult = null
                }

                client.removeLocationUpdates(this)
            }
        }
    }

    private fun invokeGetLocationCallback(location: Map<String, Double>) {
        Log.d(LOG_TAG, "invokeGetLocationCallback")

        val workRequest = OneTimeWorkRequestBuilder<BackgroundWorker>()
                .setInputData(buildInputData(location))
                .setInitialDelay(0, TimeUnit.SECONDS)
                .build()
        WorkManager.getInstance(context).enqueueUniqueWork(
                WORK_TAG,
                ExistingWorkPolicy.APPEND,
                workRequest)
    }

    private fun buildInputData(location: Map<String, Double>): Data {
        return Data.Builder()
                .putString(BackgroundWorker.DART_TASK_KEY, WORK_TAG)
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

            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }

            else -> {
                result.notImplemented()
            }
        }
    }
}
