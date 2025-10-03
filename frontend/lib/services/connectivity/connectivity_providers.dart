import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connectivity_service.dart';

final connectivityStatusProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onStatusChange;
});
