package events.pandemic.covid19

import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        Log.d("MainActivity", "configureFlutterEngine")
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.getPlugins().add(LocationPlugin())
    }

}
