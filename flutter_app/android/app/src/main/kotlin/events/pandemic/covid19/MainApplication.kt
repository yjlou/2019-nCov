package events.pandemic.covid19

import androidx.annotation.NonNull
import be.tramckrijte.workmanager.WorkmanagerPlugin
import io.flutter.app.FlutterApplication
import io.flutter.plugin.common.PluginRegistry

class MainApplication : FlutterApplication(), PluginRegistry.PluginRegistrantCallback {
    override fun onCreate() {
        super.onCreate()
        WorkmanagerPlugin.pluginRegistryCallback = this
        // LocationPlugin.pluginRegistryCallback = this
        // WorkmanagerPlugin.setPluginRegistrantCallback(this)
    }

    override fun registerWith(@NonNull registry: PluginRegistry) {
        WorkmanagerPlugin.registerWith(registry.registrarFor("be.tramckrijte.workmanager.WorkmanagerPlugin"))
        LocationPlugin.registerWith(registry.registrarFor("events.pandemic.covid19.LocationPlugin"))
        // com.lyokone.location.LocationPlugin.registerWith(registry.registrarFor("com.lyokone.location.LocationPlugin"))
    }
}