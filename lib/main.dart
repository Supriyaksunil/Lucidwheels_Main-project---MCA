import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/emergency_alert_provider.dart';
import 'providers/fleet_provider.dart';
import 'providers/monitoring_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  runApp(const LucidWheelsApp());
}

class LucidWheelsApp extends StatelessWidget {
  const LucidWheelsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MonitoringProvider()),
        ChangeNotifierProxyProvider<AuthProvider, EmergencyAlertProvider>(
          create: (_) => EmergencyAlertProvider(),
          update: (_, authProvider, emergencyAlertProvider) {
            final provider = emergencyAlertProvider ?? EmergencyAlertProvider();
            provider.bindUser(authProvider.currentUser);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, FleetProvider>(
          create: (_) => FleetProvider(),
          update: (_, authProvider, fleetProvider) {
            final provider = fleetProvider ?? FleetProvider();
            provider.bindUser(authProvider.currentUser);
            return provider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'LucidWheels',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const SplashScreen(),
      ),
    );
  }
}
