package com.example.newprg;

import android.os.Bundle;
import android.view.WindowManager;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "secure_screen";

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if (call.method.equals("enableSecureMode")) {
                        getWindow().addFlags(WindowManager.LayoutParams.FLAG_SECURE);
                        result.success("Secure mode enabled");
                    } else if (call.method.equals("disableSecureMode")) {
                        getWindow().clearFlags(WindowManager.LayoutParams.FLAG_SECURE);
                        result.success("Secure mode disabled");
                    } else {
                        result.notImplemented();
                    }
                });
    }
}
