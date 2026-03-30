import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final _connectivityController = StreamController<ConnectivityResult>.broadcast();

  Stream<ConnectivityResult> get connectivityStream => _connectivityController.stream;

  Future<void> initialize() async {
    final result = await _connectivity.checkConnectivity();
    _handleConnectivityResult(result.first);
    _connectivity.onConnectivityChanged.listen((results) {
      _handleConnectivityResult(results.first);
    });
  }

  void _handleConnectivityResult(ConnectivityResult result) {
    _connectivityController.add(result);
  }

  Future<bool> isConnected() async {
    final result = await _connectivity.checkConnectivity();
    return result.first != ConnectivityResult.none;
  }

  void dispose() {
    _connectivityController.close();
  }
}
