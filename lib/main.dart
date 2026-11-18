import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/ai_model.dart';
import 'models/generation_controller.dart';
import 'screens/create_screen.dart';
import 'screens/generate_screen.dart';
import 'screens/image_detail_screen.dart';
import 'screens/library_screen.dart';
import 'screens/settings_screen.dart';
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
  final _genController = GenerationController();
  String _ratio = '1:1';
  String _model = 'moss';
  int _steps = 8;
  String _api = _buildApiUrl.isEmpty ? 'http://192.168.29.196:8000' : _buildApiUrl;
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
            (model) =>
                model['available'] == true &&
                {'moss', 'fibo2', 'qwen_image'}.contains(model['id']),
          );
        }
      }
    } catch (_) {
      // Keep API and ComfyUI status separate.
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
      _prompt.text = job['prompt'] as String? ?? '';
      _ratio = job['aspect_ratio'] as String? ?? '1:1';
      _model = job['model'] as String? ?? 'moss';
      _steps = job['steps'] as int? ?? AiModel.fromId(_model).defaultSteps;
    });
    _genController.reset();
    _openGenerateScreen();
  }

  Future<bool> _deleteGeneration(Map<String, dynamic> job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text(
          'Delete this image?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'This removes the saved copy from this phone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC93B2B)),
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
    if (mounted) setState(() {});
    _snack('Image deleted');
    return true;
  }

  Future<void> _clearHistory() async {
    if (_history.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text(
          'Clear recent images?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'This removes saved images from this phone. It does not remove files from the generator PC.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC93B2B)),
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
    setState(() => _history = []);
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
    _genController.dispose();
    super.dispose();
  }

  String _mapApiRatio(String ratio) {
    return switch (ratio) {
      '1:1' || 'square' => 'square',
      '9:16' || 'portrait' => 'portrait',
      '16:9' || '3:2' || 'landscape' => 'landscape',
      _ => 'square',
    };
  }

  Future<void> _create() async {
    if (_prompt.text.trim().length < 3) {
      _genController.fail('Add a little more detail to your prompt.');
      return;
    }

    final initialMessage = _model == 'moss'
        ? (_steps == 8 ? 'Starting MOSS (LoRA 8 steps)…' : 'Starting MOSS in ComfyUI…')
        : _model == 'fibo2'
        ? 'Starting FIBO 2.0 in ComfyUI…'
        : _model == 'qwen_image'
        ? 'Starting Qwen Image in ComfyUI…'
        : 'Starting generator…';

    _genController.start(initialMessage, _steps);

    try {
      final apiRatio = _mapApiRatio(_ratio);
      final response = await http
          .post(
            Uri.parse('$_api/api/jobs'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'prompt': _prompt.text.trim(),
              'model': _model,
              'aspect_ratio': apiRatio,
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

      _genController.updateProgress('Saving image to this phone…', _steps, _steps, job);
      job = await _rememberGeneration(job);
      _genController.complete(job);
      if (mounted) {
        setState(() {});
        unawaited(_openImage(job));
      }
    } catch (e) {
      _genController.fail(e.toString().replaceFirst('Exception: ', ''));
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

          final completedSteps = (job['completed_steps'] as num?)?.toInt() ?? 0;
          final totalSteps = (job['steps'] as num?)?.toInt() ?? _steps;

          final msg = job['status'] == 'queued'
              ? 'Waiting for ComfyUI…'
              : job['model'] == 'moss'
              ? (totalSteps == 8
                    ? 'MOSS LoRA rendering ($completedSteps/$totalSteps)…'
                    : 'MOSS rendering ($completedSteps/$totalSteps)…')
              : job['model'] == 'fibo2'
              ? 'FIBO 2.0 rendering ($completedSteps/$totalSteps)…'
              : job['model'] == 'qwen_image'
              ? 'Qwen Image rendering ($completedSteps/$totalSteps)…'
              : 'Creating your image ($completedSteps/$totalSteps)…';

          _genController.updateProgress(msg, completedSteps, totalSteps, job);

          if (job['status'] == 'completed' || job['status'] == 'failed') {
            return job;
          }
        }

        // Fallback check if SSE ended before status completed/failed
        final check = await http.get(Uri.parse('$_api/api/jobs/$jobId'));
        if (check.statusCode == 200) {
          final j = jsonDecode(check.body) as Map<String, dynamic>;
          if (j['status'] == 'completed' || j['status'] == 'failed') {
            return j;
          }
        }

        throw const SocketException('Generation update stream ended early.');
      } catch (_) {
        if (attempt == 4) rethrow;
        _genController.updateProgress(
          'Reconnecting…',
          _genController.completedSteps,
          _genController.totalSteps,
        );
        await Future<void>.delayed(Duration(seconds: 1 << attempt));
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
  ).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.surfaceElevated,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  void _onModelChanged(String modelId) {
    setState(() {
      _model = modelId;
      final aiModel = AiModel.fromId(modelId);
      _steps = aiModel.defaultSteps;
    });
    _checkServerConnection();
  }

  void _openGenerateScreen() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => GenerateScreen(
          promptController: _prompt,
          modelId: _model,
          ratio: _ratio,
          steps: _steps,
          generationController: _genController,
          onModelChanged: _onModelChanged,
          onRatioChanged: (newRatio) => setState(() => _ratio = newRatio),
          onStepsChanged: (newSteps) => setState(() => _steps = newSteps),
          onGenerate: _create,
          onTemplateSelected: (template) {
            _prompt.text = template.prompt;
            setState(() => _ratio = template.ratio == 'portrait' ? '9:16' : template.ratio == 'landscape' ? '16:9' : '1:1');
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedTab,
          children: [
            CreateScreen(
              selectedModelId: _model,
              checkingServer: _checkingServer,
              serverOnline: _serverOnline,
              comfyOnline: _comfyOnline,
              onCheckServer: _checkServerConnection,
              onModelChanged: _onModelChanged,
              onStartCreate: _openGenerateScreen,
            ),
            LibraryScreen(
              images: _visibleHistory,
              allHistory: _history,
              totalCount: _history.length,
              filter: _libraryFilter,
              api: _api,
              onFilterChanged: (filter) => setState(() => _libraryFilter = filter),
              onClearAll: _clearHistory,
              onCreate: () => setState(() => _selectedTab = 0),
              onOpenImage: _openImage,
              onSaveImage: _save,
            ),
            SettingsScreen(
              comfyOnline: _comfyOnline,
              checkingServer: _checkingServer,
              onCheckServer: _checkServerConnection,
              onClearHistory: _clearHistory,
              historyCount: _history.length,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 0.8),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.auto_awesome_rounded,
                  label: 'Create',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final selected = _selectedTab == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF281C13) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? AppColors.accent : AppColors.textMuted,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.accentLight : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
