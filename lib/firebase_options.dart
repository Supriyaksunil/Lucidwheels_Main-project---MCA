// lib/firebase_options.dart
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAbUxaNuyH0M-IXLR-KzpZL6259pybIvSY',
    appId: '1:972543898241:web:b1e5151a5593a02f8cd380',
    messagingSenderId: '972543898241',
    projectId: 'lucidwheels-97704',
    authDomain: 'lucidwheels-97704.firebaseapp.com',
    storageBucket: 'lucidwheels-97704.firebasestorage.app',
    measurementId: 'G-E7Y4J2EEHS',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCwSKF-0B83pSBChaeXXBZyKWX4kyAIJKg',
    appId: '1:972543898241:android:85a27a1318a7f9778cd380',
    messagingSenderId: '972543898241',
    projectId: 'lucidwheels-97704',
    storageBucket: 'lucidwheels-97704.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAr_RmVJOvTKv1sPpy_ynsR9kFxgSNYwTw',
    appId: '1:972543898241:ios:0b990cf07b3b13e98cd380',
    messagingSenderId: '972543898241',
    projectId: 'lucidwheels-97704',
    storageBucket: 'lucidwheels-97704.firebasestorage.app',
    iosBundleId: 'com.example.lucidwheel',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAr_RmVJOvTKv1sPpy_ynsR9kFxgSNYwTw',
    appId: '1:972543898241:ios:0b990cf07b3b13e98cd380',
    messagingSenderId: '972543898241',
    projectId: 'lucidwheels-97704',
    storageBucket: 'lucidwheels-97704.firebasestorage.app',
    iosBundleId: 'com.example.lucidwheel',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAbUxaNuyH0M-IXLR-KzpZL6259pybIvSY',
    appId: '1:972543898241:web:a9fbd86c2cc27d948cd380',
    messagingSenderId: '972543898241',
    projectId: 'lucidwheels-97704',
    authDomain: 'lucidwheels-97704.firebaseapp.com',
    storageBucket: 'lucidwheels-97704.firebasestorage.app',
    measurementId: 'G-J92WX566JQ',
  );
}
