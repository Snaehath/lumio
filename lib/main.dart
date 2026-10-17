import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const ink = Color(0xFF201D1B);
const paper = Color(0xFFF6F3EE);
const accent = Color(0xFFB95D3D);

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
  int _steps = 30;
  String _api = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
  Map<String, dynamic>? _job;
  bool _busy = false;
  bool _editingServer = false;
  String? _error;
  String _statusMessage = 'Starting the generator…';
  bool? _serverOnline;
  bool _checkingServer = false;
  List<Map<String, dynamic>> _history = [];

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
    if (saved != null && saved.isNotEmpty && mounted) {
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
    try {
      final response = await http.get(Uri.parse('$_api/api/health')).timeout(const Duration(seconds: 5));
      online = response.statusCode == 200 && (jsonDecode(response.body) as Map<String, dynamic>)['status'] == 'ok';
    } catch (_) {
      online = false;
    }
    if (mounted) setState(() { _serverOnline = online; _checkingServer = false; });
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

  Future<Map<String, dynamic>> _rememberGeneration(Map<String, dynamic> job) async {
    final entry = <String, dynamic>{...job, 'prompt': _prompt.text.trim(), 'aspect_ratio': _ratio, 'steps': _steps};
    try {
      final response = await http.get(Uri.parse('$_api${job['image_url']}'));
      if (response.statusCode != 200) return entry;
      final documents = await getApplicationDocumentsDirectory();
      final folder = Directory('${documents.path}${Platform.pathSeparator}lumio_history');
      await folder.create(recursive: true);
      final file = File('${folder.path}${Platform.pathSeparator}${job['id']}.png');
      await file.writeAsBytes(response.bodyBytes, flush: true);
      entry['image_path'] = file.path;
      final updated = [entry, ..._history.where((item) => item['id'] != job['id'])];
      for (final old in updated.skip(12)) {
        final path = old['image_path'];
        if (path is String) await File(path).delete().catchError((_) => File(path));
      }
      _history = updated.take(12).toList();
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
      _statusMessage = 'Sending your prompt…';
    });
    try {
      final response = await http
          .post(Uri.parse('$_api/api/jobs'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'prompt': _prompt.text.trim(),
                'aspect_ratio': _ratio,
                'steps': _steps,
              }))
          .timeout(const Duration(seconds: 90));
      if (response.statusCode != 202) {
        throw Exception(_detail(response.body));
      }
      var job = jsonDecode(response.body) as Map<String, dynamic>;
      while (job['status'] == 'queued' || job['status'] == 'running') {
        if (mounted) {
          setState(() {
            _job = job;
            _statusMessage = job['status'] == 'queued'
                ? 'Waiting for the GPU…'
                : 'Creating your image…';
          });
        }
        await Future<void>.delayed(const Duration(seconds: 2));
        final status = await _getJobStatus(job['id'] as String);
        if (status.statusCode != 200) throw Exception(_detail(status.body));
        job = jsonDecode(status.body) as Map<String, dynamic>;
      }
      if (job['status'] == 'failed') throw Exception(job['error'] ?? 'Generation failed');
      if (mounted) {
        job = await _rememberGeneration(job);
        setState(() => _job = job);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<http.Response> _getJobStatus(String jobId) async {
    for (var attempt = 0; ; attempt++) {
      try {
        return await http
            .get(Uri.parse('$_api/api/jobs/$jobId'))
            .timeout(const Duration(seconds: 90));
      } on TimeoutException catch (_) {
        if (attempt >= 4) rethrow;
      } on SocketException {
        if (attempt >= 4) rethrow;
      } on http.ClientException {
        if (attempt >= 4) rethrow;
      }
      if (mounted) {
        setState(() => _statusMessage = 'Reconnecting to your image generator…');
      }
      await Future<void>.delayed(Duration(seconds: 2 << attempt));
    }
  }

  String _detail(String body) {
    try {
      final value = jsonDecode(body);
      return value['detail']?.toString() ?? 'Request failed';
    } catch (_) {
      return 'Could not reach Lumio Studio API';
    }
  }

  Future<void> _save() async {
    try {
      final permission = await Gal.hasAccess();
      if (!permission) await Gal.requestAccess();
      final image = await http.get(Uri.parse('$_api${_job!['image_url']}'));
      if (image.statusCode != 200) throw Exception('Could not download image');
      await Gal.putImageBytes(image.bodyBytes, name: 'lumio-${_job!['id']}');
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
    final progress = job == null || (job['steps'] ?? 0) == 0
        ? 0.0
        : (job['completed_steps'] as num).toDouble() / (job['steps'] as num).toDouble();
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 32),
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
                        Icon(Icons.circle, size: 8, color: _serverOnline == true ? const Color(0xFF4A8D67) : _serverOnline == false ? accent : Colors.amber),
                        const SizedBox(width: 6),
                        Text(_checkingServer ? 'Checking' : _serverOnline == true ? 'Online' : _serverOnline == false ? 'Offline' : 'Checking', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 8),                  IconButton.filledTonal(
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
                if (_history.isNotEmpty) ...[
                  const SizedBox(height: 23),
                  Row(children: [
                    _sectionLabel('RECENT CREATIONS'),
                    const Spacer(),
                    Text('Tap to reuse', style: TextStyle(fontSize: 12, color: ink.withValues(alpha: .52))),
                  ]),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 128,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _history.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 9),
                      itemBuilder: (context, index) {
                        final item = _history[index];
                        return InkWell(
                          onTap: _busy ? null : () => setState(() {
                            _job = item;
                            _prompt.text = item['prompt'] as String? ?? '';
                            _ratio = item['aspect_ratio'] as String? ?? 'portrait';
                            _steps = item['steps'] as int? ?? 30;
                          }),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 116,
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(11),
                                child: Image.file(File(item['image_path'] as String), width: double.infinity, fit: BoxFit.cover))),
                              const SizedBox(height: 6),
                              Text(item['prompt'] as String? ?? 'Untitled image', maxLines: 1,
                                overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
                ],
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
                        onTap: () => setState(() => _ratio = item.$1),
                      ),
                    )),
                ]),
                const SizedBox(height: 22),
                Row(children: [
                  _sectionLabel('DETAIL'),
                  const Spacer(),
                  Text(_steps == 30 ? 'Fine detail' : 'Balanced', style: const TextStyle(fontWeight: FontWeight.w700, color: accent)),
                ]),
                const SizedBox(height: 8),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 20, label: Text('20 steps'), icon: Icon(Icons.bolt_rounded)),
                    ButtonSegment(value: 30, label: Text('30 steps'), icon: Icon(Icons.auto_awesome_rounded)),
                  ],
                  selected: {_steps},
                  onSelectionChanged: (selection) => setState(() => _steps = selection.first),
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
                if (_busy && job != null) ...[
                  const SizedBox(height: 13),
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: progress, minHeight: 6, color: accent)),
                  const SizedBox(height: 7),
                  Text('${job['completed_steps']} of ${job['steps']} steps', textAlign: TextAlign.center,
                      style: TextStyle(color: ink.withValues(alpha: .6), fontSize: 13)),
                ],
                if (job?['status'] == 'completed') ...[
                  const SizedBox(height: 30),
                  Row(children: [
                    const Text('Made for you', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, letterSpacing: -.5)),
                    const Spacer(),
                    Text('${job!['width']} × ${job['height']}', style: TextStyle(color: ink.withValues(alpha: .55), fontSize: 12)),
                  ]),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image(image: job['image_path'] is String
                        ? FileImage(File(job['image_path'] as String))
                        : NetworkImage('$_api${job['image_url']}'), fit: BoxFit.cover,
                      loadingBuilder: (context, child, loading) => loading == null ? child : Container(
                        height: 340,
                        color: const Color(0xFFE9E3DA),
                        child: const Center(child: CircularProgressIndicator(color: accent)),
                      ),
                      errorBuilder: (_, _, _) => Container(
                        height: 180,
                        color: const Color(0xFFE9E3DA),
                        child: const Center(child: Text('Image preview unavailable. Check the server address.')),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Save to gallery'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), foregroundColor: ink),
                  ),
                ],
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String value) => Text(value,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.15, color: ink.withValues(alpha: .58)));
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

