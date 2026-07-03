import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

/// Graba audio del ambiente al activar el SOS, como evidencia.
/// Los archivos se guardan localmente en el teléfono, en una carpeta
/// "grabaciones_sos" dentro del almacenamiento propio de la app.
class AudioRecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentPath;

  Future<bool> hasPermission() => _recorder.hasPermission();

  /// Empieza a grabar. Devuelve true si arrancó correctamente.
  Future<bool> startRecording() async {
    if (!await hasPermission()) return false;
    if (await _recorder.isRecording()) return true; // ya está grabando

    final dir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${dir.path}/grabaciones_sos');
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _currentPath = '${recordingsDir.path}/audio_sos_$timestamp.m4a';

    await _recorder.start(const RecordConfig(), path: _currentPath!);
    return true;
  }

  /// Detiene la grabación. Devuelve la ruta del archivo guardado, o null
  /// si no había ninguna grabación en curso.
  Future<String?> stopRecording() async {
    if (!await _recorder.isRecording()) return null;
    final path = await _recorder.stop();
    _currentPath = null;
    return path;
  }

  Future<bool> get isRecording => _recorder.isRecording();

  void dispose() {
    _recorder.dispose();
  }
}
