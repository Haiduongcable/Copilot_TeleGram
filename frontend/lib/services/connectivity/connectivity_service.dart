import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(service.dispose);
  return service;
});

class ConnectivityService {
  ConnectivityService() {
    _subscription = Connectivity().onConnectivityChanged.listen((event) {
      _controller.add(_hasConnection(event));
    });
  }

  late final StreamSubscription<Object?> _subscription;
  final _controller = StreamController<bool>.broadcast();

  Stream<bool> get onStatusChange => _controller.stream;

  Future<bool> get isOnline async {
    final result = await Connectivity().checkConnectivity();
    return _hasConnection(result);
  }

  void dispose() {
    _subscription.cancel();
    _controller.close();
  }

  bool _hasConnection(Object? event) {
    if (event is List<ConnectivityResult>) {
      return event.any((status) => status != ConnectivityResult.none);
    }
    if (event is ConnectivityResult) {
      return event != ConnectivityResult.none;
    }
    return false;
  }
}
