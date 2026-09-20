import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../core/reminders.dart';

Future<String> prepareReminderImage() async {
  final directory = await getApplicationSupportDirectory();
  final file = File('${directory.path}/garden-reminder-v1.png');
  if (!await file.exists()) {
    final asset = await rootBundle.load(reminderImage);
    final codec = await ui.instantiateImageCodec(
      asset.buffer.asUint8List(),
      targetWidth: 720,
    );
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    await file.writeAsBytes(data!.buffer.asUint8List(), flush: true);
    frame.image.dispose();
    codec.dispose();
  }
  return file.path;
}
