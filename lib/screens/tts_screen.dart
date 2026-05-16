import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import '../services/tts_engine.dart';

class TtsScreen extends StatefulWidget {
  const TtsScreen({super.key});

  @override
  State<TtsScreen> createState() => _TtsScreenState();
}

class _TtsScreenState extends State<TtsScreen> {
  final _textController = TextEditingController(text: 'Hello, this is a text to speech example.');
  final _audioPlayer = AudioPlayer();

  TextToSpeech? _tts;
  Style? _style;
  bool _isLoading = false;
  bool _isGenerating = false;
  bool _isPlaying = false;
  String _status = '';
  double _downloadProgress = 0;
  String _selectedVoice = 'M1';
  String _selectedLang = 'en';
  int _totalSteps = 8;
  double _speed = 1.05;
  String? _lastFilePath;

  @override
  void initState() {
    super.initState();
    _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state.playing;
        if (state.processingState == ProcessingState.completed) {
          _isPlaying = false;
          _status = 'Готово';
        }
      });
    });
    _initTts();
  }

  Future<void> _initTts() async {
    setState(() {
      _isLoading = true;
      _status = 'Проверка моделей...';
    });

    try {
      print('[TTS] Starting download...');
      final dir = await TtsDownloader.ensureDownloaded((progress, status) {
        print('[TTS] Download: ${(progress * 100).toStringAsFixed(0)}% - $status');
        setState(() {
          _downloadProgress = progress;
          _status = status;
        });
      });

      print('[TTS] Download complete, loading ONNX from $dir');
      setState(() => _status = 'Загрузка ONNX сессий...');

      _tts = await loadTextToSpeech(dir);
      print('[TTS] TTS engine loaded');

      _style = await loadVoiceStyle(dir, _selectedVoice);
      print('[TTS] Voice style loaded');

      setState(() {
        _isLoading = false;
        _status = 'Готово';
      });
    } catch (e, stackTrace) {
      print('[TTS] ERROR: $e');
      print('[TTS] Stack: $stackTrace');
      setState(() {
        _isLoading = false;
        _status = 'Ошибка: $e';
      });
    }
  }

  Future<void> _generate() async {
    if (_tts == null || _style == null) return;
    if (_textController.text.trim().isEmpty) {
      setState(() => _status = 'Введите текст');
      return;
    }

    setState(() {
      _isGenerating = true;
      _status = 'Генерация речи...';
    });

    try {
      final result = await _tts!.call(
        _textController.text,
        _selectedLang,
        _style!,
        _totalSteps,
        speed: _speed,
      );

      final wav = result['wav'] as List<double>;
      final duration = (result['duration'] as List).cast<double>();

      final tempDir = await getTemporaryDirectory();
      final outputPath = '${tempDir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.wav';
      writeWavFile(outputPath, wav, _tts!.sampleRate);

      setState(() {
        _isGenerating = false;
        _lastFilePath = outputPath;
        _status = 'Воспроизведение ${duration[0].toStringAsFixed(1)}с...';
      });

      await _audioPlayer.setAudioSource(AudioSource.uri(Uri.file(outputPath)));
      await _audioPlayer.play();
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _status = 'Ошибка: $e';
      });
    }
  }

  Future<void> _changeVoice(String voice) async {
    setState(() {
      _selectedVoice = voice;
      _isLoading = true;
      _status = 'Загрузка голоса $voice...';
    });

    try {
      final dir = await TtsDownloader.ensureDownloaded((p, s) {});
      _style = await loadVoiceStyle(dir, voice);
      setState(() {
        _isLoading = false;
        _status = 'Голос $voice загружен';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Ошибка загрузки голоса: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _isLoading || _isGenerating;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Озвучка текста (Supertonic 3)'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_status.isNotEmpty) _StatusBanner(status: _status, isLoading: busy, progress: _downloadProgress),
              const SizedBox(height: 12),
              _VoiceSelector(selected: _selectedVoice, onChanged: busy ? null : _changeVoice),
              const SizedBox(height: 12),
              _LangSelector(selected: _selectedLang, onChanged: busy ? null : (v) => setState(() => _selectedLang = v)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _textController,
                  maxLines: 6,
                  enabled: !busy,
                  decoration: InputDecoration.collapsed(
                    hintText: 'Введите текст для озвучки...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                  ),
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
              const SizedBox(height: 12),
              _ParamSlider(label: 'Шаги денойзинга', value: _totalSteps.toDouble(), min: 1, max: 20, divisions: 19, enabled: !busy, onChanged: (v) => setState(() => _totalSteps = v.toInt())),
              _ParamSlider(label: 'Скорость', value: _speed, min: 0.5, max: 2.0, divisions: 30, enabled: !busy, onChanged: (v) => setState(() => _speed = v)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: busy
                      ? null
                      : _isPlaying
                          ? () async { await _audioPlayer.stop(); setState(() => _status = 'Готово'); }
                          : _generate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A2E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor: Colors.grey[300],
                    elevation: 0,
                  ),
                  child: _isGenerating
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                            const SizedBox(width: 8),
                            Text(_isPlaying ? 'Остановить' : 'Озвучить', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}

class _StatusBanner extends StatelessWidget {
  final String status;
  final bool isLoading;
  final double progress;
  const _StatusBanner({required this.status, required this.isLoading, required this.progress});

  @override
  Widget build(BuildContext context) {
    final isError = status.startsWith('Ошибка');
    final color = isLoading ? Colors.blue : isError ? Colors.red : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          if (isLoading) ...[
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: color)),
            const SizedBox(width: 10),
          ] else ...[
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, size: 18, color: color),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(status, style: TextStyle(color: color.withValues(alpha: 0.9), fontSize: 13))),
          if (isLoading && progress > 0 && progress < 1)
            Text('${(progress * 100).toStringAsFixed(0)}%', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _VoiceSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String>? onChanged;
  const _VoiceSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Голос', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[600])),
        const SizedBox(height: 6),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: voiceStyles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final voice = voiceStyles[i];
              final isSelected = voice == selected;
              return ChoiceChip(
                label: Text(voice, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400)),
                selected: isSelected,
                onSelected: onChanged != null ? (_) => onChanged!(voice) : null,
                selectedColor: const Color(0xFF1A1A2E),
                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LangSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String>? onChanged;
  const _LangSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Язык', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[600])),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButton<String>(
            value: selected,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            items: ttsLangs.map((lang) => DropdownMenuItem(
              value: lang,
              child: Text('${ttsLangNames[lang] ?? lang} ($lang)', style: const TextStyle(fontSize: 14)),
            )).toList(),
            onChanged: onChanged != null ? (String? v) { if (v != null) onChanged!(v); } : null,
          ),
        ),
      ],
    );
  }
}

class _ParamSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final bool enabled;
  final ValueChanged<double> onChanged;
  const _ParamSlider({required this.label, required this.value, required this.min, required this.max, required this.divisions, required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 140, child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600]))),
        Expanded(
          child: Slider(value: value, min: min, max: max, divisions: divisions, onChanged: enabled ? onChanged : null),
        ),
        SizedBox(
          width: 50,
          child: Text(value is int ? value.toStringAsFixed(0) : value.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}
