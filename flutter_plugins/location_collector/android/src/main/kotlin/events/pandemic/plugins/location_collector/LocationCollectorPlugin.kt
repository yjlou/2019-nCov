package events.pandemic.plugins.location_collector

import android.content.Context
import android.util.Log
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

/** LocationCollectorPlugin */
class LocationCollectorPlugin: FlutterPlugin {
  // This static function is optional and equivalent to onAttachedToEngine. It supports the old
  // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
  // plugin registration via this function while apps migrate to use the new Android APIs
  // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
  //
  // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
  // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
  // depending on the user's project. onAttachedToEngine or registerWith must both be defined
  // in the same class.
  companion object {
    private val LOG_TAG = "LocationCollectorPlugin"

    @JvmStatic
    fun registerWith(registrar: Registrar) {
      Log.d(LOG_TAG, "registerWith")
      val instance = LocationCollectorPlugin()
      instance.onAttachedToEngine(registrar.messenger(), registrar.activeContext())
    }
  }

  private var channel: MethodChannel? = null
  private var handler: LocationPluginHandler? = null

  private fun onAttachedToEngine(messenger: BinaryMessenger, context: Context) {
    handler = LocationPluginHandler(context)
    channel = MethodChannel(messenger, "events.pandemic.plugins.location_collector")
    channel!!.setMethodCallHandler(handler)
  }

  override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    Log.d(LOG_TAG, "onAttachedToEngine")
    onAttachedToEngine(binding.binaryMessenger, binding.applicationContext)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    Log.d(LOG_TAG, "onDetachedFromEngine")
    channel?.setMethodCallHandler(null)
    channel = null
    handler = null
  }
}
