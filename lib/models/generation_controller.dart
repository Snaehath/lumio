import 'package:flutter/material.dart';

class GenerationController extends ChangeNotifier {
  bool _busy = false;
  String _statusMessage = 'Starting generator…';
  int _completedSteps = 0;
  int _totalSteps = 8;
  String? _error;
  Map<String, dynamic>? _lastJob;

  bool get busy => _busy;
  String get statusMessage => _statusMessage;
  int get completedSteps => _completedSteps;
  int get totalSteps => _totalSteps;
  String? get error => _error;
  Map<String, dynamic>? get lastJob => _lastJob;

  void start(String message, int total) {
    _busy = true;
    _statusMessage = message;
    _completedSteps = 0;
    _totalSteps = total;
    _error = null;
    _lastJob = null;
    notifyListeners();
  }

  void updateProgress(String message, int completed, int total, [Map<String, dynamic>? job]) {
    _statusMessage = message;
    _completedSteps = completed;
    _totalSteps = total;
    if (job != null) _lastJob = job;
    notifyListeners();
  }

  void complete(Map<String, dynamic> job) {
    _busy = false;
    _statusMessage = 'Complete';
    _completedSteps = _totalSteps;
    _lastJob = job;
    _error = null;
    notifyListeners();
  }

  void fail(String err) {
    _busy = false;
    _error = err;
    notifyListeners();
  }

  void reset() {
    _busy = false;
    _error = null;
    notifyListeners();
  }
}
