import 'dart:async';

class IndexManager {
  static final IndexManager _instance = IndexManager._internal();
  factory IndexManager() => _instance;

  IndexManager._internal();

  final StreamController<int> _indexStreamController = StreamController<int>.broadcast();
  Stream<int> get indexStream => _indexStreamController.stream;

  void updateIndex(int newIndex) {
    _indexStreamController.add(newIndex);
  }

  void dispose() {
    _indexStreamController.close();
  }
}
