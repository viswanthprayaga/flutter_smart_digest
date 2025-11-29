
package com.example.smart_digest.services;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterEngineCache;


import android.service.notification.NotificationListenerService;
import android.service.notification.StatusBarNotification;
import android.util.Log;
import java.util.HashMap;
import java.util.Map;
import io.flutter.plugin.common.EventChannel;

public class MyNotificationListener extends NotificationListenerService {

    private static EventChannel.EventSink eventSink;

    public static void setEventSink(EventChannel.EventSink sink) {
        eventSink = sink;
    }

    @Override
    public void onNotificationPosted(StatusBarNotification sbn) {
        try {
            String pkg = sbn.getPackageName();
            CharSequence title = sbn.getNotification().extras.getCharSequence("android.title");
            CharSequence text = sbn.getNotification().extras.getCharSequence("android.text");

            Log.d("SmartDigest", "Notification from: " + pkg + " | Title: " + title + " | Text: " + text);

            if (eventSink != null) {
                Map<String, Object> data = new HashMap<>();
                data.put("package", pkg);
                data.put("title", title != null ? title.toString() : "");
                data.put("text", text != null ? text.toString() : "");
                eventSink.success(data);
            }
        } catch (Exception e) {
            Log.e("SmartDigest", "Error: " + e.getMessage());
        }
    }
}
