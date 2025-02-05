import 'dart:io';
import 'package:path_provider/path_provider.dart';

class Logger {
  static Future<void> log(String message) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/debug_log.txt');
      await file.writeAsString('${DateTime.now()}: $message\n', mode: FileMode.append);
    } catch (e) {
      // Handle any errors silently
    }
  }
}