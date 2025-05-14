// import 'package:flutter/services.dart';
// import 'package:flutter/material.dart';
//
// class ScreenshotDetector {
//   static const MethodChannel _channel = MethodChannel('screenshot_detector');
//
//   static void initialize() {
//     _channel.setMethodCallHandler(_handleMethodCall);
//   }
//
//   static Future<void> _handleMethodCall(MethodCall call) async {
//     if (call.method == 'onScreenshotTaken') {
//       // Show an error message when a screenshot is taken
//       showDialog(
//         context: navigatorKey.currentContext!,
//         builder: (context) => AlertDialog(
//           title: Text('Error'),
//           content: Text('Screenshots are not allowed in this app.'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: Text('OK'),
//             ),
//           ],
//         ),
//       );
//     }
//   }
// }