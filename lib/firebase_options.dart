import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      _ => throw UnsupportedError(
        'Firebase is configured for EcoRoute on web and Android.',
      ),
    };
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAOR0PVIsQZergiHFT38-OqMSsZaZvuuH4',
    appId: '1:947341991096:web:5f5f159a0c6dcc0f08e84d',
    messagingSenderId: '947341991096',
    projectId: 'ecoroute-58d2d',
    authDomain: 'ecoroute-58d2d.firebaseapp.com',
    storageBucket: 'ecoroute-58d2d.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAOR0PVIsQZergiHFT38-OqMSsZaZvuuH4',
    appId: '1:947341991096:android:5f5f159a0c6dcc0f08e84d',
    messagingSenderId: '947341991096',
    projectId: 'ecoroute-58d2d',
    storageBucket: 'ecoroute-58d2d.firebasestorage.app',
  );
}
