import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Returns Pianora's private, persistent data directory on desktop and mobile.
/// The Windows location intentionally matches older releases so upgrades keep
/// all existing profiles and practice history.
Future<Directory?> pianoraSupportDirectory() async {
  try {
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      if (appData == null || appData.isEmpty) return null;
      return Directory('$appData${Platform.pathSeparator}Pianora');
    }

    final root = await getApplicationSupportDirectory();
    return Directory('${root.path}${Platform.pathSeparator}Pianora');
  } catch (_) {
    return null;
  }
}
