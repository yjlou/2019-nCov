package events.pandemic.covid19

import androidx.annotation.NonNull
import be.tramckrijte.workmanager.WorkmanagerPlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        // We already done this
//        flutterEngine.getPlugins().add(LocationPlugin())
//        GeneratedPluginRegistrant.registerWith(flutterEngine)
    }

}
