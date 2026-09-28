import 'package:shared_preferences/shared_preferences.dart';

/// Atomic local snapshot storage. UI and business logic use GardenStore.
abstract class GardenRepository {
  Future<String?> read();
  Future<void> write(String value);
}

/// Retained for legacy migration and recovery. Never remove the original key
/// until a separately verified backup/retention policy permits it.
class LocalGardenRepository implements GardenRepository {
  static const key = 'money_plant.garden.v1';
  final SharedPreferencesAsync preferences = SharedPreferencesAsync();

  @override
  Future<String?> read() => preferences.getString(key);

  @override
  Future<void> write(String value) => preferences.setString(key, value);
}
