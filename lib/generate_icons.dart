import 'package:flutter/material.dart';
import 'utils/icon_generator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🎨 Generating MessX app icons...');
  await IconGenerator.generateMessXIcons();
  print('✅ Icon generation complete!');
}
