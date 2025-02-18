import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const platform = MethodChannel('secure_screen');
  bool _secureMode = false;

  // Create a GlobalKey for the ScaffoldMessenger
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
  GlobalKey<ScaffoldMessengerState>();

  Future<void> _toggleSecureMode() async {
    try {
      if (_secureMode) {
        await platform.invokeMethod('disableSecureMode');
        // Use the GlobalKey to access the ScaffoldMessenger
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text("Secure Mode Disabled")),
        );
      } else {
        await platform.invokeMethod('enableSecureMode');
        // Use the GlobalKey to access the ScaffoldMessenger
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text("Screenshots are now blocked!")),
        );
      }

      setState(() {
        _secureMode = !_secureMode;
      });
    } on PlatformException catch (e) {
      print("Failed to toggle secure mode: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Secure Screen App',
      theme: ThemeData(primarySwatch: Colors.green),
      // Use the GlobalKey for the ScaffoldMessenger
      scaffoldMessengerKey: _scaffoldMessengerKey,
      home: Scaffold(
        appBar: AppBar(title: const Text('Prevent Screenshot')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Secure Mode: $_secureMode\n'),
              ElevatedButton(
                onPressed: _toggleSecureMode,
                child: Text(_secureMode ? "Disable Secure Mode" : "Enable Secure Mode"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}