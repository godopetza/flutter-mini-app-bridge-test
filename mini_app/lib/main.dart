import 'package:flutter/material.dart';
import 'dart:async';
import 'pages/home_page.dart';
import 'services/bank_bridge.dart';
import 'services/mock_bridge.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  BankBridge? _bridge;
  StreamSubscription? _resetSubscription;

  @override
  void initState() {
    super.initState();
    _initializeBridge();
  }

  Future<void> _initializeBridge() async {
    try {
      // Try to initialize the real bridge first
      _bridge = BankBridge();
      await _bridge!.initialize();

      // Listen for reset messages
      _resetSubscription = _bridge!.resetStream.listen((_) {
        print('[MyApp] Reset to home received, navigating to home');
        _navigateToHome();
      });

    } catch (e) {
      print('[MyApp] Failed to initialize BankBridge, falling back to MockBridge: $e');
      // Fall back to mock bridge for development
      _bridge = MockBridge();
      await _bridge!.initialize();

      // Listen for reset messages
      _resetSubscription = _bridge!.resetStream.listen((_) {
        print('[MyApp] Reset to home received, navigating to home');
        _navigateToHome();
      });
    }
  }

  void _navigateToHome() {
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      // Pop all routes to get back to the root (HomePage)
      navigator.popUntil((route) => route.isFirst);
    }
  }

  @override
  void dispose() {
    _resetSubscription?.cancel();
    _bridge?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Mini App Bridge Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}