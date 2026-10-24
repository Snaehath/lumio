import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const ink = Color(0xFF201D1B);
const paper = Color(0xFFF6F3EE);
const accent = Color(0xFFB95D3D);
const _buildApiUrl = String.fromEnvironment('API_BASE_URL');

const _promptTemplates = [
  (
    title: 'Lantern street',
    tag: 'LIGHT & REFLECTIONS',
    icon: Icons.nightlight_round,
    ratio: 'portrait',
    prompt:
        'A rain-soaked Kyoto side street at blue hour, paper lanterns reflected in the pavement, a lone cyclist passing, cinematic photography, intricate architecture, warm amber light, realistic details.',
  ),
  (
    title: 'Cobalt teapot',
    tag: 'PRODUCT TEXTURE',
    icon: Icons.coffee_rounded,
    ratio: 'square',
    prompt:
        'A handcrafted ceramic teapot with deep cobalt glaze on natural linen, soft morning window light, editorial product photography, crisp glaze texture, gentle shadows, uncluttered warm studio.',
  ),
  (
    title: 'Rooftop glasshouse',
    tag: 'ATMOSPHERE',
    icon: Icons.park_rounded,
    ratio: 'portrait',
    prompt:
        'A tiny greenhouse on a rooftop at night, glowing plants behind rain-streaked glass, distant city lights, cinematic illustration, rich botanical detail, atmospheric blue and amber lighting.',
  ),
  (
    title: 'The old knight',
    tag: 'MATERIAL & DETAIL',
    icon: Icons.shield_moon_rounded,
    ratio: 'landscape',
    prompt:
        'A weathered medieval knight with a broad sword standing on a windswept ridge, dramatic clouds, engraved steel, grounded fantasy concept art, precise armor details, cinematic natural light.',
  ),
];

void main() => runApp(const LumioApp());

class LumioApp extends StatelessWidget {
  const LumioApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Lumio',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: paper,
          colorScheme: ColorScheme.fromSeed(
            seedColor: accent,
            brightness: Brightness.light,
            surface: paper,
          ),
          fontFamily: 'Roboto',
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
          ),
        ),
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
      final response = await http.get(Uri.parse('$_api/api/health')).timeout(const Duration(seconds: 5));
      online = response.statusCode == 200 &&
          (jsonDecode(response.body) as Map<String, dynamic>)['status'] == 'ok';
      if (online) {
        final models = await http.get(Uri.parse('$_api/api/models')).timeout(const Duration(seconds: 5));
        if (models.statusCode == 200) {
          final entries = (jsonDecode(models.body) as List).cast<Map<String, dynamic>>();
          comfyOnline = entries.any((model) => model['id'] == 'moss' && model['available'] == true);
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
        builder: (_) => _ImageDetailScreen(
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return false;

    final path = job['image_path'];
    if (path is String) await File(path).delete().catchError((_) => File(path));
    _history.removeWhere((item) => item['id'] == job['id']);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList('generation_history', _history.map(jsonEncode).toList());
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
        content: const Text('This removes saved images from this phone. It does not remove files from the generator PC.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear history')),
        ],
      ),
    );
    if (confirmed != true) return;

    final paths = _history.map((item) => item['image_path']).whereType<String>().toSet();
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

  Future<Map<String, dynamic>> _rememberGeneration(Map<String, dynamic> job) async {
    final entry = <String, dynamic>{...job, 'prompt': job['prompt'] ?? _prompt.text.trim(), 'aspect_ratio': job['aspect_ratio'] ?? _ratio, 'steps': job['steps'] ?? _steps, 'model': job['model'] ?? _model};
    try {
      final response = await http.get(Uri.parse('$_api${job['image_url']}'));
      if (response.statusCode != 200) return entry;
      final documents = await getApplicationDocumentsDirectory();
      final folder = Directory('${documents.path}${Platform.pathSeparator}lumio_history');
      await folder.create(recursive: true);
      final file = File('${folder.path}${Platform.pathSeparator}${job['id']}.png');
      await file.writeAsBytes(response.bodyBytes, flush: true);
      entry['image_path'] = file.path;
        _history = [entry, ..._history.where((item) => item['id'] != job['id'])];
      final preferences = await SharedPreferences.getInstance();
      await preferences.setStringList('generation_history', _history.map(jsonEncode).toList());
    } catch (_) {
      if (mounted) _snack('Image created, but it could not be added to history.');
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
          .post(Uri.parse('$_api/api/jobs'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'prompt': _prompt.text.trim(),
                'model': _model,
                'aspect_ratio': _ratio,
                'steps': _steps,
              }))
          .timeout(const Duration(seconds: 90));
      if (response.statusCode != 202) {
        throw Exception(_detail(response.body));
      }
      var job = jsonDecode(response.body) as Map<String, dynamic>;
      if (job['status'] == 'queued' || job['status'] == 'running') {
        job = await _watchJob(job['id'] as String);
      }
      if (job['status'] == 'failed') throw Exception(job['error'] ?? 'Generation failed');
      if (mounted) setState(() => _statusMessage = 'Saving the image to this phone…');
      if (mounted) {
        job = await _rememberGeneration(job);
        setState(() => _job = job);
        unawaited(_openImage(job));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<Map<String, dynamic>> _watchJob(String jobId) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final client = http.Client();
      try {
        final request = http.Request('GET', Uri.parse('$_api/api/jobs/$jobId/events'));
        final response = await client.send(request);
        if (response.statusCode != 200) {
          throw Exception('Could not follow generation updates (${response.statusCode}).');
        }

        await for (final line in response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
          if (!line.startsWith('data:')) continue;
          final job = jsonDecode(line.substring(5).trim()) as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _job = job;
              _statusMessage = job['status'] == 'queued'
                  ? (job['model'] == 'sana' ? 'Waiting for the GPU…' : 'Waiting for ComfyUI…')
                  : job['model'] == 'moss'
                      ? 'MOSS is rendering in ComfyUI…'
                      : job['model'] == 'fibo2'
                          ? 'FIBO 2.0 is rendering in ComfyUI…'
                          : 'Creating your image…';
            });
          }
          if (job['status'] == 'completed' || job['status'] == 'failed') return job;
        }
        throw const SocketException('Generation update stream ended early.');
      } catch (_) {
        if (attempt == 4) rethrow;
        if (mounted) {
          setState(() => _statusMessage = 'Reconnecting to your image generator…');
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

  void _snack(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _saveServer() async {
    final value = _serverController.text.trim().replaceFirst(RegExp(r'/$'), '');
    final uri = Uri.tryParse(value);
    if (uri == null || !{'http', 'https'}.contains(uri.scheme) || uri.host.isEmpty) {
      setState(() => _error = 'Enter a valid server address, such as http://192.168.1.20:8000');
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
    final totalSteps = job?['steps'] ?? _steps;
    final progress = completedSteps is num && totalSteps is num && totalSteps > 0
        ? (completedSteps / totalSteps).clamp(0.0, 1.0).toDouble()
        : null;

    return Scaffold(
      body: SafeArea(
        child: _selectedTab == 0
            ? CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(22, 10, 22, 28),
                    sliver: SliverList.list(children: [
                      Row(children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 21),
                        ),
                        const SizedBox(width: 11),
                        const Text('lumio', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -1)),
                        const Spacer(),
                        InkWell(
                          onTap: _checkServerConnection,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.circle, size: 8, color: _checkingServer
                                  ? Colors.amber
                                  : _serverOnline != true || (_model != 'sana' && _comfyOnline == false)
                                      ? accent
                                      : const Color(0xFF4A8D67)),
                              const SizedBox(width: 6),
                              Text(
                                _checkingServer
                                    ? 'Checking'
                                    : _serverOnline != true
                                        ? 'API offline'
                                        : _model != 'sana' && _comfyOnline != null
                                            ? _comfyOnline! ? 'ComfyUI online' : 'ComfyUI offline'
                                            : 'API online',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ]),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: 'Server settings',
                          onPressed: () => setState(() {
                            _editingServer = !_editingServer;
                            _serverController.text = _api;
                          }),
                          icon: Icon(_editingServer ? Icons.close_rounded : Icons.tune_rounded),
                        ),
                      ]),
                      if (_editingServer) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Connect to your PC', style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 9),
                            TextField(
                              controller: _serverController,
                              keyboardType: TextInputType.url,
                              decoration: const InputDecoration(
                                labelText: 'Server address',
                                hintText: 'http://192.168.1.20:8000',
                              ),
                            ),
                            const SizedBox(height: 9),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton(onPressed: _saveServer, child: const Text('Save address')),
                            ),
                          ]),
                        ),
                      ],
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 20, 18, 18),
                        decoration: BoxDecoration(
                          color: ink,
                          borderRadius: BorderRadius.circular(26),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF292522), Color(0xFF171514)],
                          ),
                        ),
                        child: Stack(children: [
                          Positioned(
                            right: 8,
                            top: 2,
                            child: Icon(Icons.auto_awesome_rounded, size: 74, color: Colors.white.withValues(alpha: .07)),
                          ),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.circle, size: 7, color: Color(0xFFE9A27E)),
                              const SizedBox(width: 7),
                              Text('YOUR CREATIVE STUDIO',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.35,
                                      color: Colors.white.withValues(alpha: .72))),
                            ]),
                            const SizedBox(height: 18),
                            const Text('Your next idea,\nbeautifully made.',
                                style: TextStyle(fontSize: 31, height: 1.08, fontWeight: FontWeight.w700,
                                    letterSpacing: -1.25, color: Colors.white)),
                            const SizedBox(height: 10),
                            Text('Describe a scene. Make it yours.',
                                style: TextStyle(color: Colors.white.withValues(alpha: .68), fontSize: 14)),
                          ]),
                        ]),
                      ),
                      const SizedBox(height: 25),
                      Row(children: [
                        _sectionLabel('QUICK PROMPTS'),
                        const Spacer(),
                        Text('Tap to try', style: TextStyle(fontSize: 12, color: ink.withValues(alpha: .52))),
                      ]),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 94,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _promptTemplates.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 9),
                          itemBuilder: (context, index) {
                            final template = _promptTemplates[index];
                            return _TemplateCard(
                              title: template.title,
                              tag: template.tag,
                              icon: template.icon,
                              onTap: () {
                                setState(() {
                                  _prompt.value = TextEditingValue(
                                    text: template.prompt,
                                    selection: TextSelection.collapsed(offset: template.prompt.length),
                                  );
                                  _ratio = template.ratio;
                                  _error = null;
                                });
                                FocusScope.of(context).unfocus();
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 23),
                      _sectionLabel('DESCRIBE YOUR IMAGE'),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _prompt,
                        minLines: 4,
                        maxLines: 7,
                        maxLength: 2000,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'A tiny glass greenhouse on a rainy rooftop at blue hour, warm lights glowing inside…',
                          hintMaxLines: 3,
                          contentPadding: EdgeInsets.all(18),
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 22),
                      _sectionLabel('MODEL'),
                      const SizedBox(height: 10),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'sana', label: Text('SANA')),
                          ButtonSegment(value: 'moss', label: Text('MOSS')),
                          ButtonSegment(value: 'fibo2', label: Text('FIBO 2')),
                        ],
                        selected: {_model},
                        onSelectionChanged: _busy ? null : (selection) {
                          setState(() {
                            _model = selection.first;
                            _steps = _model == 'sana' ? 30 : 25;
                          });
                          _checkServerConnection();
                        },
                        showSelectedIcon: false,
                      ),
                      const SizedBox(height: 6),
                      Text(_model == 'moss'
                          ? '8 steps uses your LoRA. 25 and 50 steps use the base model.'
                          : _model == 'fibo2'
                              ? 'FIBO 2.0 runs in ComfyUI at 25 steps.'
                              : 'SANA runs directly in the local API.',
                          style: TextStyle(fontSize: 12, color: ink.withValues(alpha: .58))),
                      const SizedBox(height: 22),
                      _sectionLabel('CANVAS'),
                      const SizedBox(height: 10),
                      Row(children: [
                        for (final item in [('portrait', 'Portrait', Icons.crop_portrait_rounded), ('square', 'Square', Icons.crop_square_rounded), ('landscape', 'Landscape', Icons.crop_landscape_rounded)])
                          Expanded(child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _ChoicePill(
                              selected: _ratio == item.$1,
                              label: item.$2,
                              icon: item.$3,
                              onTap: _busy ? () {} : () => setState(() => _ratio = item.$1),
                            ),
                          )),
                      ]),
                      const SizedBox(height: 22),
                      Row(children: [
                        _sectionLabel('DETAIL'),
                        const Spacer(),
                        Text(
                          _model == 'fibo2'
                              ? '25 steps'
                              : _model == 'moss'
                                  ? (_steps == 8 ? 'Fast LoRA' : _steps == 50 ? 'Fine detail' : 'Balanced')
                                  : (_steps == 30 ? 'Fine detail' : 'Balanced'),
                          style: const TextStyle(fontWeight: FontWeight.w700, color: accent),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      if (_model != 'fibo2')
                        SegmentedButton<int>(
                          segments: _model == 'moss'
                              ? const [
                                  ButtonSegment(value: 8, label: Text('8 steps'), icon: Icon(Icons.bolt_rounded)),
                                  ButtonSegment(value: 25, label: Text('25 steps'), icon: Icon(Icons.auto_awesome_rounded)),
                                  ButtonSegment(value: 50, label: Text('50 steps')),
                                ]
                              : const [
                                  ButtonSegment(value: 20, label: Text('20 steps'), icon: Icon(Icons.bolt_rounded)),
                                  ButtonSegment(value: 30, label: Text('30 steps'), icon: Icon(Icons.auto_awesome_rounded)),
                                ],
                          selected: {_steps},
                          onSelectionChanged: _busy ? null : (selection) => setState(() => _steps = selection.first),
                          showSelectedIcon: false,
                        ),
                      const SizedBox(height: 20),
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: const Color(0xFFFFE8E2), borderRadius: BorderRadius.circular(16)),
                          child: Text(_error!, style: const TextStyle(color: Color(0xFF873C2A))),
                        ),
                        const SizedBox(height: 12),
                      ],
                      FilledButton.icon(
                        onPressed: _busy ? null : _create,
                        icon: _busy
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.auto_awesome_rounded),
                        label: Text(_busy ? _statusMessage : 'Create image'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(58),
                          backgroundColor: ink,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (_busy && _model != 'sana') ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: ink.withValues(alpha: .06)),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              const SizedBox(width: 28, height: 28,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: accent)),
                              const SizedBox(width: 13),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(_statusMessage, style: const TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 3),
                                Text(_model == 'moss'
                                    ? 'MOSS can take a few minutes. Keep Lumio open.'
                                    : 'FIBO 2.0 can take a few minutes. Keep Lumio open.',
                                    style: TextStyle(fontSize: 12, color: ink.withValues(alpha: .58))),
                              ])),
                              const SizedBox(width: 8),
                              Text('${completedSteps is num ? completedSteps.toInt() : 0} of $totalSteps steps',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ink.withValues(alpha: .7))),
                            ]),
                            const SizedBox(height: 14),
                            ClipRRect(borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(value: progress, minHeight: 4, color: accent)),
                          ]),
                        ),
                      ],
                      if (_busy && _model == 'sana') ...[
                        const SizedBox(height: 14),
                        Text(
                          '${completedSteps is num ? completedSteps.toInt() : 0} of $totalSteps steps',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: ink.withValues(alpha: .65), fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(value: progress, minHeight: 6, color: accent),
                        ),
                      ],
                    ]),
                  ),
                ],
              )
            : _buildLibrary(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.auto_awesome_rounded), label: 'Create'),
          NavigationDestination(icon: Icon(Icons.photo_library_outlined), label: 'Library'),
        ],
      ),
    );
  }

  Widget _buildLibrary() {
    final images = _visibleHistory;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
          sliver: SliverList.list(children: [
            Row(children: [
              const Text('Your library', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: -.8)),
              const Spacer(),
              if (_history.isNotEmpty)
                TextButton(onPressed: _clearHistory, child: const Text('Clear all')),
            ]),
            const SizedBox(height: 4),
            Text('${_history.length} ${_history.length == 1 ? 'image' : 'images'} saved on this phone',
                style: TextStyle(fontSize: 13, color: ink.withValues(alpha: .56))),
            if (_history.isNotEmpty) ...[
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  for (final filter in [('all', 'All'), ('sana', 'SANA'), ('moss', 'MOSS'), ('fibo2', 'FIBO 2')])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter.$2),
                        selected: _libraryFilter == filter.$1,
                        onSelected: (_) => setState(() => _libraryFilter = filter.$1),
                        selectedColor: const Color(0xFFF0DFD8),
                      ),
                    ),
                ]),
              ),
            ],
          ]),
        ),
        if (_history.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.collections_outlined, size: 42, color: ink.withValues(alpha: .38)),
                const SizedBox(height: 12),
                const Text('Your images will live here', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Create an image and it will be saved to this library.',
                    textAlign: TextAlign.center, style: TextStyle(color: ink.withValues(alpha: .58))),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => setState(() => _selectedTab = 0),
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Create an image'),
                ),
              ]),
            )),
          )
        else if (images.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('No ${_libraryFilter == 'fibo2' ? 'FIBO 2' : _libraryFilter.toUpperCase()} images yet.',
                style: TextStyle(color: ink.withValues(alpha: .58)))),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: .72,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) {
                final image = images[index];
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _openImage(image),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: Stack(fit: StackFit.expand, children: [
                        _imageFor(image, fit: BoxFit.cover),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: .58), borderRadius: BorderRadius.circular(20)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              child: Text(_modelName(image['model'] as String? ?? 'sana'),
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                      ])),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                        child: Text(image['prompt'] as String? ?? 'Untitled image', maxLines: 2,
                            overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _imageFor(Map<String, dynamic> image, {required BoxFit fit}) {
    final path = image['image_path'];
    if (path is String) {
      return Image.file(File(path), fit: fit, errorBuilder: (_, _, _) => _imageFallback());
    }
    final url = image['image_url'];
    if (url is String) {
      return Image.network('$_api$url', fit: fit, errorBuilder: (_, _, _) => _imageFallback());
    }
    return _imageFallback();
  }

  Widget _imageFallback() => Container(
        color: const Color(0xFFE9E3DA),
        child: const Center(child: Icon(Icons.image_not_supported_outlined, color: accent)),
      );

  String _modelName(String model) => switch (model) {
        'moss' => 'MOSS',
        'fibo2' => 'FIBO 2',
        _ => 'SANA',
      };
  Widget _sectionLabel(String value) => Text(value,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.15, color: ink.withValues(alpha: .58)));
}

class _ImageDetailScreen extends StatelessWidget {
  const _ImageDetailScreen({
    required this.job,
    required this.api,
    required this.onSave,
    required this.onDelete,
    required this.onReuse,
  });

  final Map<String, dynamic> job;
  final String api;
  final Future<void> Function() onSave;
  final Future<bool> Function() onDelete;
  final VoidCallback onReuse;

  @override
  Widget build(BuildContext context) {
    final model = switch (job['model']) {
      'moss' => 'MOSS',
      'fibo2' => 'FIBO 2.0',
      _ => 'SANA',
    };
    final width = job['width'] ?? '?';
    final height = job['height'] ?? '?';
    final prompt = job['prompt'] as String? ?? 'Untitled image';

    return Scaffold(
      backgroundColor: const Color(0xFF191715),
      appBar: AppBar(
        backgroundColor: const Color(0xFF191715),
        foregroundColor: Colors.white,
        title: Text(model),
        actions: [
          IconButton(
            tooltip: 'Delete image',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              if (await onDelete() && context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: SizedBox.expand(child: _preview(fit: BoxFit.contain)),
          ),
        ),
        Container(
          width: double.infinity,
          color: paper,
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(prompt, maxLines: 4, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, height: 1.4, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Wrap(spacing: 7, runSpacing: 7, children: [
                    _detailChip('$width × $height'),
                    _detailChip('${job['steps'] ?? '?'} steps'),
                    _detailChip((job['aspect_ratio'] as String? ?? 'square').toUpperCase()),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onSave,
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Save image'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: ink,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          onReuse();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.replay_rounded),
                        label: const Text('Reuse prompt'),
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), foregroundColor: ink),
                      ),
                    ),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _preview({required BoxFit fit}) {
    final path = job['image_path'];
    if (path is String) {
      return Image.file(File(path), fit: fit,
          errorBuilder: (_, _, _) => const Center(child: Text('Image preview unavailable', style: TextStyle(color: Colors.white70))));
    }
    final imageUrl = job['image_url'];
    if (imageUrl is String) {
      return Image.network('$api$imageUrl', fit: fit,
          errorBuilder: (_, _, _) => const Center(child: Text('Image preview unavailable', style: TextStyle(color: Colors.white70))));
    }
    return const Center(child: Text('Image preview unavailable', style: TextStyle(color: Colors.white70)));
  }

  Widget _detailChip(String label) => Chip(
        visualDensity: VisualDensity.compact,
        backgroundColor: Colors.white,
        side: BorderSide.none,
        label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      );
}
class _ChoicePill extends StatelessWidget {
  const _ChoicePill({required this.selected, required this.label, required this.icon, required this.onTap});
  final bool selected;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? const Color(0xFFF0DFD8) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(children: [
              Icon(icon, size: 20, color: selected ? accent : ink.withValues(alpha: .65)),
              const SizedBox(height: 5),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? accent : ink)),
            ]),
          ),
        ),
      );
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.title,
    required this.tag,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String tag;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Container(
            width: 164,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: ink.withValues(alpha: .06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(icon, size: 18, color: accent),
                  const Spacer(),
                  Icon(Icons.add_rounded, size: 16, color: ink.withValues(alpha: .48)),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(tag, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 9, letterSpacing: .55, fontWeight: FontWeight.w700,
                          color: ink.withValues(alpha: .48))),
                ]),
              ],
            ),
          ),
        ),
      );
}

