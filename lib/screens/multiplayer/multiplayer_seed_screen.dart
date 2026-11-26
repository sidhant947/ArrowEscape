import 'dart:math';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_colors.dart';
import '../../core/app_themes.dart';
import '../../core/audio_haptic_helper.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../game/game_screen.dart';

class MultiplayerSeedScreen extends ConsumerStatefulWidget {
  const MultiplayerSeedScreen({super.key});

  @override
  ConsumerState<MultiplayerSeedScreen> createState() =>
      _MultiplayerSeedScreenState();
}

class _MultiplayerSeedScreenState extends ConsumerState<MultiplayerSeedScreen> {
  late String _roomCode;
  final _inputController = TextEditingController();
  String? _inputError;

  @override
  void initState() {
    super.initState();
    _generateNewRoomCode();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _generateNewRoomCode() {
    final rng = Random();
    final codeNum = rng.nextInt(899999) + 100000;
    setState(() {
      _roomCode = 'ROOM-$codeNum';
    });
  }

  int _codeToLevelNumber(String code) {
    final cleaned = code.trim().toUpperCase().replaceAll('ROOM-', '').replaceAll('AE-', '');
    if (cleaned.isEmpty) return 1;
    final parsed = int.tryParse(cleaned);
    if (parsed != null && parsed > 0) return parsed;
    return (cleaned.hashCode.abs() % 999999) + 1;
  }

  void _playRoom(String code) {
    AudioHapticHelper.playClick();
    final levelNum = _codeToLevelNumber(code);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(level: levelNum, isRandom: true),
      ),
    );
  }

  void _copyRoomCode() {
    AudioHapticHelper.playClick();
    final l10n = AppLocalizations.of(context)!;
    Clipboard.setData(ClipboardData(text: _roomCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.roomCodeCopied(_roomCode)),
        backgroundColor: AppColors.surfaceLight,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressRepositoryProvider);
    final themeColors = AppThemes.getThemeColors(progress.selectedTheme);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.multiplayerTitle,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: themeColors.textPrimary,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: themeColors.bgGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: themeColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: themeColors.accentColor.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.groups_rounded,
                          color: themeColors.accentColor,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          l10n.hostRoomTitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: themeColors.textPrimary,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.hostRoomDesc,
                      style: TextStyle(
                        fontSize: 13,
                        color: themeColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: themeColors.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _roomCode,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: themeColors.accentColor,
                              letterSpacing: 2,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.refresh,
                                  color: themeColors.textSecondary,
                                ),
                                tooltip: l10n.tooltipNewCode,
                                onPressed: () {
                                  AudioHapticHelper.playClick();
                                  _generateNewRoomCode();
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.copy,
                                  color: themeColors.textPrimary,
                                ),
                                tooltip: l10n.tooltipCopyCode,
                                onPressed: _copyRoomCode,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColors.accentColor,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _playRoom(_roomCode),
                      icon: const Icon(Icons.play_arrow_rounded, size: 24),
                      label: Text(
                        l10n.startMatch,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: themeColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: themeColors.surfaceLight,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.meeting_room_rounded,
                          color: themeColors.accentColor,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          l10n.joinRoomTitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: themeColors.textPrimary,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.joinRoomDesc,
                      style: TextStyle(
                        fontSize: 13,
                        color: themeColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _inputController,
                      style: TextStyle(
                        color: themeColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: l10n.joinRoomHint,
                        hintStyle: TextStyle(
                          color: themeColors.textMuted,
                          letterSpacing: 1.0,
                        ),
                        filled: true,
                        fillColor: themeColors.surfaceLight,
                        errorText: _inputError,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: themeColors.accentColor,
                            width: 1.5,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.paste,
                            color: themeColors.textSecondary,
                          ),
                          onPressed: () async {
                            final data = await Clipboard.getData('text/plain');
                            if (data?.text != null) {
                              _inputController.text = data!.text!;
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColors.surfaceLight,
                        foregroundColor: themeColors.textPrimary,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: themeColors.accentColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onPressed: () {
                        final text = _inputController.text.trim();
                        if (text.isEmpty) {
                          setState(() {
                            _inputError = l10n.joinRoomErrorEmpty;
                          });
                          return;
                        }
                        setState(() {
                          _inputError = null;
                        });
                        _playRoom(text);
                      },
                      icon: const Icon(Icons.sports_esports_rounded, size: 24),
                      label: Text(
                        l10n.joinMatch,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
