package com.example.smart_digest

import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.EventChannel
import com.example.smart_digest.services.MyNotificationListener

class MainActivity : FlutterActivity() {
    private val CHANNEL = "smartdigest/notifications"

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    MyNotificationListener.setEventSink(events)
                }

                override fun onCancel(arguments: Any?) {
                    MyNotificationListener.setEventSink(null)
                }
            })
    }
}
