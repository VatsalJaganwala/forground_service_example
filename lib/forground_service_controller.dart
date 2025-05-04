import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

initialiseService() {
  final service = FlutterBackgroundService();
  service.configure(
    iosConfiguration: IosConfiguration(autoStart: true, onForeground: onStart, onBackground: onIosBackground),
    androidConfiguration: AndroidConfiguration(onStart: onStart, isForegroundMode: true, autoStart: true),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  DartPluginRegistrant.ensureInitialized();
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Start periodic increment
  Timer.periodic(const Duration(seconds: 5), (timer) async {
    final prefs = await SharedPreferences.getInstance();
    const String key = 'increment_counter';
    await prefs.reload();
    int current = prefs.getInt(key) ?? 0;
    current += 1;
    await prefs.setInt(key, current);
    _counter = current;

    if (kDebugMode) {
      print('Counter: $_counter');
    }

    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(title: 'Counter Running', content: 'Current Count: $_counter');
    }

    service.invoke('update');
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

int _counter = 0;
