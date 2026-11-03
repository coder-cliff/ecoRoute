import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        // Use web configuration as standard fallback for desktop and tests
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAS_mpVMPe5ug8tW32bpuvyTfq7hjainhA',
    appId: '1:412809123352:web:af337060362283f3a3156d',
    messagingSenderId: '412809123352',
    projectId: 'ecoroute-b3405',
    authDomain: 'ecoroute-b3405.firebaseapp.com',
    storageBucket: 'ecoroute-b3405.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDqa9hJs4vuESU3aLQrs80rQihAGMtXF-4',
    appId: '1:412809123352:android:73fb50540e9fa5c0a3156d',
    messagingSenderId: '412809123352',
    projectId: 'ecoroute-b3405',
    storageBucket: 'ecoroute-b3405.firebasestorage.app',
  );
}
