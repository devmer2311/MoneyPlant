import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as mobile;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<(DatabaseFactory, String)> gardenDatabaseLocation() async {
  final directory = await getApplicationSupportDirectory();
  await directory.create(recursive: true);
  final factory = Platform.isAndroid || Platform.isIOS || Platform.isMacOS
      ? mobile.databaseFactory
      : databaseFactoryFfi;
  return (
    factory,
    '${directory.path}${Platform.pathSeparator}money_plant.sqlite',
  );
}
