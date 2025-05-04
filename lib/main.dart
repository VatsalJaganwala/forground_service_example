import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'forground_service_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  checkNotificationPermission().then((value) {
    final service = FlutterBackgroundService();

    service.isRunning().then((value) {
      if (!value) {
        initialiseService();
      }
    });
  });
  runApp(const MyApp());
}

Future<bool> checkNotificationPermission() async {
  bool granted = await Permission.notification.isGranted;
  if (!granted) {
    granted = await Permission.notification.request() == PermissionStatus.granted;
  }
  return granted;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Foreground Counter App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Foreground Counter'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const String counterKey = 'increment_counter';
  int _counter = 0;
  late final SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initPrefs();
    _startSyncLoop();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _loadCounter();
  }

  void _startSyncLoop() {
    // Poll every second to update UI from background counter
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return false;
      _loadCounter();
      return true;
    });
  }

  Future<void> _loadCounter() async {
    await _prefs.reload();
    final current = _prefs.getInt(counterKey) ?? 0;
    if (mounted) {
      setState(() => _counter = current);
    }
  }

  Future<void> _resetCounter() async {
    await _prefs.setInt(counterKey, 0);
    setState(() => _counter = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetCounter,
            tooltip: 'Reset Counter',
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Background Counter Running:'),
            Text('$_counter', style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      ),
    );
  }
}
