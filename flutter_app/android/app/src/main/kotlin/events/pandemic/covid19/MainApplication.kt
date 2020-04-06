package events.pandemic.covid19

import android.util.Log
import be.tramckrijte.workmanager.WorkmanagerPlugin
import io.flutter.app.FlutterApplication
import io.flutter.plugin.common.PluginRegistry
import rekab.app.background_locator.LocatorService

class MainApplication : FlutterApplication(), PluginRegistry.PluginRegistrantCallback {
    companion object {
        private val LOG_TAG = "MainApplication"
    }

    override fun onCreate() {
        super.onCreate()
        // I give up... let's fallback to embedding v1 style...
        LocatorService.setPluginRegistrant(this)
        WorkmanagerPlugin.setPluginRegistrantCallback(this)
    }

    override fun registerWith(registry: PluginRegistry?) {
        // this is so stupid...

        if (registry == null) return

        // register(registry, "rekab.app.background_locator.BackgroundLocatorPlugin")
        register(registry, "com.it_nomads.fluttersecurestorage.FlutterSecureStoragePlugin")
        register(registry, "com.example.fluttershare.FlutterSharePlugin")
        // register(registry, "com.lyokone.location.LocationPlugin")
        register(registry, "events.pandemic.plugins.location_collector.LocationCollectorPlugin")
        register(registry, "com.baseflow.location_permissions.LocationPermissionsPlugin")
        register(registry, "io.flutter.plugins.pathprovider.PathProviderPlugin")
        register(registry, "com.tekartik.sqflite.SqflitePlugin")
        register(registry, "be.tramckrijte.workmanager.WorkmanagerPlugin")
    }

    private fun register(registry: PluginRegistry, pluginName: String) {
        try {
            Log.d(LOG_TAG, "Trying to register ${pluginName}")
            val pluginClass = Class.forName(pluginName)
            val registerWith = pluginClass.getDeclaredMethod("registerWith", PluginRegistry.Registrar::class.java)

            if (registry.hasPlugin(pluginName)) {
                return
            }
            registerWith.invoke(null, registry.registrarFor(pluginName))
        } catch (exception: NoSuchMethodException) {
            Log.d(LOG_TAG, "Ignored: ${exception.message}")
        } catch (exception: ClassNotFoundException) {
            Log.d(LOG_TAG, "Ignored: ${exception.message}")
        }
    }
}