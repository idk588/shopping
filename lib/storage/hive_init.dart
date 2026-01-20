import 'package:hive_flutter/hive_flutter.dart';
import 'keys.dart';

class HiveInit {
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(HiveKeys.listsBox);
  }
}
