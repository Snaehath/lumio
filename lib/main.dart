import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/create_screen.dart';
import 'screens/image_detail_screen.dart';
import 'screens/library_screen.dart';
import 'theme/app_theme.dart';

const _buildApiUrl = String.fromEnvironment('API_BASE_URL');

void main() => runApp(const LumioApp());

class LumioApp extends StatelessWidget {
  const LumioApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Lumio',
    debugShowCheckedModeBanner: false,
    theme: buildLumioTheme(),
    home: const StudioPage(),
  );
}

class StudioPage extends StatefulWidget {
  const StudioPage({super.key});

  @override
  State<StudioPage> createState() => _StudioPageState();
}

class _StudioPageState extends State<StudioPage> {
  final _prompt = TextEditingController();
  final _serverController = TextEditingController();
  String _ratio = 'portrait';
  String _model = 'sana';
  int _steps = 30;
  String _api = _buildApiUrl.isEmpty ? 'http://10.0.2.2:8000' : _buildApiUrl;
  Map<String, dynamic>? _job;
  bool _busy = false;
  bool _editingServer = false;
  String? _error;
  String _statusMessage = 'Starting the generator…';
  bool? _serverOnline;
  bool? _comfyOnline;
  bool _checkingServer = false;
  List<Map<String, dynamic>> _history = [];
  String _libraryFilter = 'all';
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _serverController.text = _api;
    _loadSavedServer();
    _loadHistory();
  }

  Future<void> _loadSavedServer() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString('api_base_url');
    if (_buildApiUrl.isEmpty && saved != null && saved.isNotEmpty && mounted) {
      setState(() {
        _api = saved;
        _serverController.text = saved;
      });
    }
    if (mounted) await _checkServerConnection();
  }

  Future<void> _checkServerConnection() async {
    if (_checkingServer) return;
    setState(() => _checkingServer = true);
    var online = false;
    bool? comfyOnline;
    try {
      final response = await http
          .get(Uri.parse('$_api/api/health'))
          .timeout(const Duration(seconds: 5));
      online =
          response.statusCode == 200 &&
          (jsonDecode(response.body) as Map<String, dynamic>)['status'] == 'ok';
      if (online) {
        final models = await http
            .get(Uri.parse('$_api/api/models'))
            .timeout(const Duration(seconds: 5));
        if (models.statusCode == 200) {
          final entries = (jsonDecode(models.body) as List)
              .cast<Map<String, dynamic>>();
          comfyOnline = entries.any(
            (model) => model['id'] == 'moss' && model['available'] == true,
          );
        }
      }
    } catch (_) {
      // Keep API and ComfyUI status separate so a stopped ComfyUI is not reported as a dead API.
    }
    if (mounted) {
      setState(() {
        _serverOnline = online;
        _comfyOnline = comfyOnline;
        _checkingServer = false;
      });
    }
  }

  Future<void> _loadHistory() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getStringList('generation_history') ?? [];
    final entries = <Map<String, dynamic>>[];
    for (final value in saved) {
      try {
        final item = jsonDecode(value) as Map<String, dynamic>;
        final path = item['image_path'];
        if (path is String && await File(path).exists()) entries.add(item);
      } catch (_) {
        // Ignore incomplete history entries.
      }
    }
    if (mounted) setState(() => _history = entries);
  }

  List<Map<String, dynamic>> get _visibleHistory {
    if (_libraryFilter == 'all') return _history;
    return _history.where((item) => item['model'] == _libraryFilter).toList();
  }

  Future<void> _openImage(Map<String, dynamic> job) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ImageDetailScreen(
          job: job,
          api: _api,
          onSave: () => _save(job),
          onDelete: () => _deleteGeneration(job),
          onReuse: () => _reuseGeneration(job),
        ),
      ),
    );
  }

  void _reuseGeneration(Map<String, dynamic> job) {
    setState(() {
      _selectedTab = 0;
      _prompt.text = job['prompt'] as String? ?? '';
      _ratio = job['aspect_ratio'] as String? ?? 'portrait';
      _model = job['model'] as String? ?? 'sana';
      _steps = job['steps'] as int? ?? (_model == 'sana' ? 30 : 25);
      _error = null;
      _job = null;
    });
  }

  Future<bool> _deleteGeneration(Map<String, dynamic> job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this image?'),
        content: const Text('This removes the saved copy from this phone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;

    final path = job['image_path'];
    if (path is String) await File(path).delete().catchError((_) => File(path));
    _history.removeWhere((item) => item['id'] == job['id']);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      'generation_history',
      _history.map(jsonEncode).toList(),
    );
    if (!mounted) return true;
    setState(() {
      if (_job?['id'] == job['id']) _job = null;
    });
    _snack('Image deleted');
    return true;
  }

  Future<void> _clearHistory() async {
    if (_history.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear recent images?'),
        content: const Text(
          'This removes saved images from this phone. It does not remove files from the generator PC.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear history'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final paths = _history
        .map((item) => item['image_path'])
        .whereType<String>()
        .toSet();
    for (final path in paths) {
      await File(path).delete().catchError((_) => File(path));
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('generation_history');
    if (!mounted) return;
    setState(() {
      _history = [];
      if (paths.contains(_job?['image_path'])) _job = null;
    });
    _snack('Recent images cleared');
  }

  Future<Map<String, dynamic>> _rememberGeneration(
    Map<String, dynamic> job,
  ) async {
    final entry = <String, dynamic>{
      ...job,
      'prompt': job['prompt'] ?? _prompt.text.trim(),
      'aspect_ratio': job['aspect_ratio'] ?? _ratio,
      'steps': job['steps'] ?? _steps,
      'model': job['model'] ?? _model,
    };
    try {
      final response = await http.get(Uri.parse('$_api${job['image_url']}'));
      if (response.statusCode != 200) return entry;
      final documents = await getApplicationDocumentsDirectory();
      final folder = Directory(
        '${documents.path}${Platform.pathSeparator}lumio_history',
      );
      await folder.create(recursive: true);
      final file = File(
        '${folder.path}${Platform.pathSeparator}${job['id']}.png',
      );
      await file.writeAsBytes(response.bodyBytes, flush: true);
      entry['image_path'] = file.path;
      _history = [entry, ..._history.where((item) => item['id'] != job['id'])];
      final preferences = await SharedPreferences.getInstance();
      await preferences.setStringList(
        'generation_history',
        _history.map(jsonEncode).toList(),
      );
    } catch (_) {
      if (mounted) {
        _snack('Image created, but it could not be added to history.');
      }
    }
    return entry;
  }

  @override
  void dispose() {
    _prompt.dispose();
    _serverController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_prompt.text.trim().length < 3) {
      setState(() => _error = 'Add a little more detail to your prompt.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _job = null;
      _statusMessage = _model == 'sana'
          ? 'Sending your prompt…'
          : _model == 'moss'
          ? 'Starting MOSS in ComfyUI…'
          : 'Starting FIBO 2.0 in ComfyUI…';
    });
    try {
      final response = await http
          .post(
            Uri.parse('$_api/api/jobs'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'prompt': _prompt.text.trim(),
              'model': _model,
              'aspect_ratio': _ratio,
              'steps': _steps,
            }),
          )
          .timeout(const Duration(seconds: 90));
      if (response.statusCode != 202) {
        throw Exception(_detail(response.body));
      }
      var job = jsonDecode(response.body) as Map<String, dynamic>;
      if (job['status'] == 'queued' || job['status'] == 'running') {
        job = await _watchJob(job['id'] as String);
      }
      if (job['status'] == 'failed') {
        throw Exception(job['error'] ?? 'Generation failed');
      }
      if (mounted) {
        setState(() => _statusMessage = 'Saving the image to this phone…');
      }
      if (mounted) {
        job = await _rememberGeneration(job);
        setState(() => _job = job);
        unawaited(_openImage(job));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<Map<String, dynamic>> _watchJob(String jobId) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final client = http.Client();
      try {
        final request = http.Request(
          'GET',
          Uri.parse('$_api/api/jobs/$jobId/events'),
        );
        final response = await client.send(request);
        if (response.statusCode != 200) {
          throw Exception(
            'Could not follow generation updates (${response.statusCode}).',
          );
        }

        await for (final line
            in response.stream
                .transform(utf8.decoder)
                .transform(const LineSplitter())) {
          if (!line.startsWith('data:')) continue;
          final job =
              jsonDecode(line.substring(5).trim()) as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _job = job;
              _statusMessage = job['status'] == 'queued'
                  ? (job['model'] == 'sana'
                        ? 'Waiting for the GPU…'
                        : 'Waiting for ComfyUI…')
                  : job['model'] == 'moss'
                  ? 'MOSS is rendering in ComfyUI…'
                  : job['model'] == 'fibo2'
                  ? 'FIBO 2.0 is rendering in ComfyUI…'
                  : 'Creating your image…';
            });
          }
          if (job['status'] == 'completed' || job['status'] == 'failed') {
            return job;
          }
        }
        throw const SocketException('Generation update stream ended early.');
      } catch (_) {
        if (attempt == 4) rethrow;
        if (mounted) {
          setState(
            () => _statusMessage = 'Reconnecting to your image generator…',
          );
        }
        await Future<void>.delayed(Duration(seconds: 2 << attempt));
      } finally {
        client.close();
      }
    }
    throw const SocketException('Could not reconnect to the image generator.');
  }

  String _detail(String body) {
    try {
      final value = jsonDecode(body);
      return value['detail']?.toString() ?? 'Request failed';
    } catch (_) {
      return 'Could not reach Lumio Studio API';
    }
  }

  Future<void> _save(Map<String, dynamic> job) async {
    try {
      final permission = await Gal.hasAccess();
      if (!permission) await Gal.requestAccess();
      final path = job['image_path'];
      final bytes = path is String && await File(path).exists()
          ? await File(path).readAsBytes()
          : (await http.get(Uri.parse('$_api${job['image_url']}'))).bodyBytes;
      await Gal.putImageBytes(bytes, name: 'lumio-${job['id']}');
      if (mounted) _snack('Saved to your gallery');
    } catch (e) {
      if (mounted) _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _snack(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _saveServer() async {
    final value = _serverController.text.trim().replaceFirst(RegExp(r'/$'), '');
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !{'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty) {
      setState(
        () => _error =
            'Enter a valid server address, such as http://192.168.1.20:8000',
      );
      return;
    }
    setState(() {
      _api = value;
      _editingServer = false;
      _error = null;
    });
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('api_base_url', value);
    await _checkServerConnection();
  }

  @override
  Widget build(BuildContext context) {
    final job = _job;
    final completedSteps = job?['completed_steps'];
    final completedStepCount = completedSteps is num
        ? completedSteps.toInt()
        : 0;
    final totalSteps = (job?['steps'] as num?)?.toInt() ?? _steps;

    return Scaffold(
      body: SafeArea(
        child: _selectedTab == 0
            ? CreateScreen(
                promptController: _prompt,
                serverController: _serverController,
                model: _model,
                ratio: _ratio,
                steps: _steps,
                completedSteps: completedStepCount,
                totalSteps: totalSteps,
                statusMessage: _statusMessage,
                busy: _busy,
                editingServer: _editingServer,
                checkingServer: _checkingServer,
                serverOnline: _serverOnline,
                comfyOnline: _comfyOnline,
                error: _error,
                onCheckServer: _checkServerConnection,
                onToggleSettings: () => setState(() {
                  _editingServer = !_editingServer;
                  _serverController.text = _api;
                }),
                onSaveServer: _saveServer,
                onCreate: _create,
                onTemplateSelected: (template) => setState(() {
                  _prompt.value = TextEditingValue(
                    text: template.prompt,
                    selection: TextSelection.collapsed(
                      offset: template.prompt.length,
                    ),
                  );
                  _ratio = template.ratio;
                  _error = null;
                }),
                onModelChanged: (model) {
                  setState(() {
                    _model = model;
                    _steps = model == 'sana' ? 30 : 25;
                  });
                  _checkServerConnection();
                },
                onRatioChanged: (ratio) => setState(() => _ratio = ratio),
                onStepsChanged: (steps) => setState(() => _steps = steps),
              )
            : _buildLibrary(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_rounded),
            label: 'Create',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            label: 'Library',
          ),
        ],
      ),
    );
  }

  Widget _buildLibrary() => LibraryScreen(
    images: _visibleHistory,
    totalCount: _history.length,
    filter: _libraryFilter,
    api: _api,
    onFilterChanged: (filter) => setState(() => _libraryFilter = filter),
    onClearAll: _clearHistory,
    onCreate: () => setState(() => _selectedTab = 0),
    onOpenImage: _openImage,
  );
}
