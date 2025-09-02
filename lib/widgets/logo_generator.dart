import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'messx_logo.dart';

class LogoGenerator {
  static Future<void> generateAppIcons() async {
    // Icon sizes needed for Android and iOS
    final sizes = [
      20, 29, 40, 48, 58, 60, 72, 76, 80, 87, 96, 100, 114, 120, 144, 152, 167, 180, 192, 196, 216, 256, 512, 1024
    ];

    for (final size in sizes) {
      await _generateIcon(size);
    }
  }

  static Future<void> _generateIcon(int size) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Create MessX logo
    final logoPainter = MessXLogoPainter(color: Colors.purple);
    logoPainter.paint(canvas, Size(size.toDouble(), size.toDouble()));
    
    final picture = recorder.endRecording();
    final img = await picture.toImage(size, size);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();
    
    // Save to appropriate directories
    await _saveIcon(pngBytes, size);
  }

  static Future<void> _saveIcon(Uint8List bytes, int size) async {
    // Android mipmap directories
    final androidPaths = {
      48: 'android/app/src/main/res/mipmap-mdpi/ic_launcher.png',
      72: 'android/app/src/main/res/mipmap-hdpi/ic_launcher.png',
      96: 'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png',
      144: 'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png',
      192: 'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
    };

    // iOS icon paths
    final iosPaths = {
      20: 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png',
      40: 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png',
      60: 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png',
      29: 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png',
      58: 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png',
      87: 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png',
      40: 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png',
      80: 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png',
      120: 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png',
      120: 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png',
      180: 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png',
      76: 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png',
      152: 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png',
      167: 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png',
      1024: 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png',
    };

    // Save Android icons
    if (androidPaths.containsKey(size)) {
      final file = File(androidPaths[size]!);
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
      print('Generated Android icon: ${androidPaths[size]}');
    }

    // Save iOS icons
    if (iosPaths.containsKey(size)) {
      final file = File(iosPaths[size]!);
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
      print('Generated iOS icon: ${iosPaths[size]}');
    }
  }
}
