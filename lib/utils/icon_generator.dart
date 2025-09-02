import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IconGenerator {
  static Future<void> generateMessXIcons() async {
    // Create the MessX logo design
    final iconData = await _createMessXIcon();
    
    // Generate all required sizes
    await _generateAllSizes(iconData);
  }

  static Future<Uint8List> _createMessXIcon() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = 1024.0; // High resolution base
    
    // Background circle with gradient
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size / 2, size / 2),
        size / 2,
        [
          const Color(0xFF9C27B0), // Purple
          const Color(0xFF673AB7), // Deep purple
        ],
      );
    
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);
    
    // Draw "MX" text
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'MX',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
          letterSpacing: -size * 0.02,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    final textOffset = Offset(
      (size - textPainter.width) / 2,
      (size - textPainter.height) / 2,
    );
    textPainter.paint(canvas, textOffset);
    
    // Add chat bubble decorations
    final bubblePaint = Paint()..color = Colors.white.withOpacity(0.3);
    
    // Top right bubble
    canvas.drawCircle(
      Offset(size * 0.75, size * 0.25),
      size * 0.08,
      bubblePaint,
    );
    
    // Bottom left bubble
    canvas.drawCircle(
      Offset(size * 0.25, size * 0.75),
      size * 0.06,
      bubblePaint,
    );
    
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData!.buffer.asUint8List();
  }

  static Future<void> _generateAllSizes(Uint8List baseIcon) async {
    // Android sizes
    final androidSizes = {
      'mipmap-mdpi': 48,
      'mipmap-hdpi': 72,
      'mipmap-xhdpi': 96,
      'mipmap-xxhdpi': 144,
      'mipmap-xxxhdpi': 192,
    };

    // iOS sizes
    final iosSizes = {
      'Icon-App-20x20@1x': 20,
      'Icon-App-20x20@2x': 40,
      'Icon-App-20x20@3x': 60,
      'Icon-App-29x29@1x': 29,
      'Icon-App-29x29@2x': 58,
      'Icon-App-29x29@3x': 87,
      'Icon-App-40x40@1x': 40,
      'Icon-App-40x40@2x': 80,
      'Icon-App-40x40@3x': 120,
      'Icon-App-60x60@2x': 120,
      'Icon-App-60x60@3x': 180,
      'Icon-App-76x76@1x': 76,
      'Icon-App-76x76@2x': 152,
      'Icon-App-83.5x83.5@2x': 167,
      'Icon-App-1024x1024@1x': 1024,
    };

    // Generate Android icons
    for (final entry in androidSizes.entries) {
      final resizedIcon = await _resizeIcon(baseIcon, entry.value);
      final androidPath = 'android/app/src/main/res/${entry.key}/ic_launcher.png';
      await _saveIcon(resizedIcon, androidPath);
    }

    // Generate iOS icons
    for (final entry in iosSizes.entries) {
      final resizedIcon = await _resizeIcon(baseIcon, entry.value);
      final iosPath = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/${entry.key}.png';
      await _saveIcon(resizedIcon, iosPath);
    }

    // Save base icon to assets
    await _saveIcon(baseIcon, 'assets/icons/messx_logo.png');
    
    print('✅ Generated MessX icons for all platforms!');
  }

  static Future<Uint8List> _resizeIcon(Uint8List originalIcon, int size) async {
    final codec = await ui.instantiateImageCodec(
      originalIcon,
      targetWidth: size,
      targetHeight: size,
    );
    final frame = await codec.getNextFrame();
    final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  static Future<void> _saveIcon(Uint8List iconData, String path) async {
    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsBytes(iconData);
    print('Generated: $path');
  }
}
