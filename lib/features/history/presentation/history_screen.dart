import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/neon_background.dart';
import '../data/history_repository.dart';
import '../domain/history_entry.dart';

final historyRepositoryProvider = Provider((ref) => HistoryRepository());
final historyProvider = FutureProvider((ref) => ref.watch(historyRepositoryProvider).getAll());

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final AudioPlayer _player = AudioPlayer();
  String? _playingId;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay(HistoryEntry entry) async {
    if (entry.audioPath == null) return;
    if (_playingId == entry.id) {
      await _player.stop();
      setState(() => _playingId = null);
      return;
    }
    await _player.stop();
    await _player.play(DeviceFileSource(entry.audioPath!));
    setState(() => _playingId = entry.id);
    _player.onPlayerComplete.first.then((_) {
      if (mounted) setState(() => _playingId = null);
    });
  }

  Future<void> _shareAudio(HistoryEntry entry) async {
    if (entry.audioPath == null) return;
    await Share.shareXFiles(
      [XFile(entry.audioPath!)],
      text: 'Grabación de audio · Guardian SOS · ${_formatDate(entry.timestamp)}',
    );
  }

  Future<void> _openLocation(HistoryEntry entry) async {
    final uri = Uri.parse(entry.googleMapsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatDate(DateTime d) {
    final date = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    final time = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '$date · $time';
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Historial')),
      body: NeonBackground(
        child: SafeArea(
          child: historyAsync.when(
            data: (entries) {
              if (entries.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Aún no hay emergencias registradas.\nCuando actives el SOS, va a aparecer aquí.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: AppColors.textMuted),
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 66, 16, 16),
                itemCount: entries.length,
                itemBuilder: (context, i) {
                  final entry = entries[i];
                  final isPlaying = _playingId == entry.id;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.glassLight,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: [AppColors.dangerRed, AppColors.accentPink]),
                              ),
                              child: const Icon(Icons.warning_rounded, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_formatDate(entry.timestamp),
                                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                                  Text('Batería al momento: ${entry.batteryLevel}%',
                                      style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => _openLocation(entry),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_rounded, color: AppColors.accentCyan, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  entry.address ?? '${entry.latitude.toStringAsFixed(5)}, ${entry.longitude.toStringAsFixed(5)}',
                                  style: GoogleFonts.inter(color: AppColors.accentCyan, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (entry.audioPath != null && File(entry.audioPath!).existsSync()) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => _togglePlay(entry),
                                icon: Icon(
                                  isPlaying ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
                                  color: AppColors.accentPink,
                                  size: 32,
                                ),
                              ),
                              Text(isPlaying ? 'Reproduciendo…' : 'Audio grabado',
                                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
                              const Spacer(),
                              IconButton(
                                onPressed: () => _shareAudio(entry),
                                icon: const Icon(Icons.share_rounded, color: AppColors.textMuted, size: 20),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accentPink)),
            error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.textMuted))),
          ),
        ),
      ),
    );
  }
}
