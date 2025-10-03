import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../flavors/flavor_config.dart';

final appConfigProvider = Provider<FlavorConfig>((ref) {
  return FlavorConfig.instance;
});
