import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_colors.dart';
import '../../core/app_themes.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showUnlockDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _UnlockDialog(ref: ref),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          l10n.settingsTitle,
          style: TextStyle(
            fontSize: 24,
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
              const SizedBox(height: 20),
              Text(
                l10n.themeSectionTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: themeColors.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: GameTheme.values.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final theme = GameTheme.values[index];
                    final isSelected = progress.selectedTheme == theme;
                    final isDefaultUnlocked =
                        theme == GameTheme.classic ||
                        theme == GameTheme.neon ||
                        theme == GameTheme.retro ||
                        theme == GameTheme.cyber ||
                        theme == GameTheme.paper;
                    final isLocked =
                        !isDefaultUnlocked && !progress.skinsUnlocked;
                    final previewColors = AppThemes.getThemeColors(theme);

                    return GestureDetector(
                      onTap: () {
                        if (isLocked) {
                          _showUnlockDialog(context, ref);
                        } else {
                          ref.read(progressRepositoryProvider).setTheme(theme);
                        }
                      },
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: previewColors.bgGradient,
                          border: Border.all(
                            color: isSelected
                                ? previewColors.accentColor
                                : themeColors.surfaceLight,
                            width: isSelected ? 3 : 1.5,
                          ),
                        ),
                        child: Center(
                          child: isLocked
                              ? Icon(
                                  Icons.lock,
                                  color: previewColors.isLight
                                      ? const Color(0xFF8C95A3)
                                      : AppColors.textMuted,
                                  size: 20,
                                )
                              : Container(
                                  width: 24,
                                  height: 24,
                                  decoration: previewColors.arrowPalette != null
                                      ? const BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: SweepGradient(
                                            colors: [
                                              Color(0xFFFF5252),
                                              Color(0xFFFF9100),
                                              Color(0xFFFFEA00),
                                              Color(0xFF00E676),
                                              Color(0xFF00E5FF),
                                              Color(0xFF7C4DFF),
                                              Color(0xFFFF4081),
                                              Color(0xFFFF5252),
                                            ],
                                          ),
                                        )
                                      : BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: previewColors.arrowColor,
                                          border: Border.all(
                                            color: Colors.white24,
                                            width: 1,
                                          ),
                                        ),
                                  child: isSelected
                                      ? Icon(
                                          Icons.check,
                                          size: 16,
                                          color: previewColors.arrowColor
                                                      .computeLuminance() >
                                                  0.5
                                              ? Colors.black
                                              : Colors.white,
                                        )
                                      : null,
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.preferencesSectionTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: themeColors.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              _buildPreferenceTile(
                title: l10n.prefHapticsTitle,
                description: l10n.prefHapticsDesc,
                value: progress.hapticsEnabled,
                onChanged: (_) =>
                    ref.read(progressRepositoryProvider).toggleHaptics(),
                accentColor: themeColors.accentColor,
                themeColors: themeColors,
              ),
              const SizedBox(height: 14),
              _buildPreferenceTile(
                title: l10n.prefInfiniteLivesTitle,
                description: l10n.prefInfiniteLivesDesc,
                value: progress.heartRemover,
                onChanged: (_) =>
                    ref.read(progressRepositoryProvider).toggleHeartRemover(),
                accentColor: themeColors.accentColor,
                themeColors: themeColors,
              ),
              const SizedBox(height: 14),
              _buildPreferenceTile(
                title: l10n.prefTapAssistTitle,
                description: l10n.prefTapAssistDesc,
                value: progress.assistMode,
                onChanged: (_) =>
                    ref.read(progressRepositoryProvider).toggleAssistMode(),
                accentColor: themeColors.accentColor,
                themeColors: themeColors,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferenceTile({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color accentColor,
    required ThemeColors themeColors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: themeColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColors.surfaceLight, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: themeColors.textPrimary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: themeColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: accentColor,
            activeTrackColor: accentColor.withValues(alpha: 0.3),
            inactiveThumbColor: themeColors.textMuted,
            inactiveTrackColor: themeColors.surfaceLight,
          ),
        ],
      ),
    );
  }
}

class _UnlockDialog extends StatefulWidget {
  final WidgetRef ref;

  const _UnlockDialog({required this.ref});

  @override
  State<_UnlockDialog> createState() => _UnlockDialogState();
}

class _UnlockDialogState extends State<_UnlockDialog> {
  final _controller = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.ref.watch(progressRepositoryProvider);
    final themeColors = AppThemes.getThemeColors(progress.selectedTheme);
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: themeColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: themeColors.accentColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.unlockThemeTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: themeColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.unlockThemeDesc,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: themeColors.textSecondary),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFDD00),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  try {
                    await launchUrl(
                       Uri.parse('https://buymeacoffee.com/sidhant947/e/562696'),
                      mode: LaunchMode.externalApplication,
                    );
                  } catch (_) {}
                },
                icon: const Icon(Icons.local_cafe, size: 20),
                label: Text(
                  l10n.getUnlockCode,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                style: TextStyle(color: themeColors.textPrimary),
                decoration: InputDecoration(
                  hintText: l10n.enterUnlockCodeHint,
                  hintStyle: TextStyle(color: themeColors.textMuted),
                  filled: true,
                  fillColor: themeColors.surfaceLight,
                  errorText: _errorMessage,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: themeColors.accentColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      l10n.dialogCancel,
                      style: TextStyle(color: themeColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColors.accentColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      final code = _controller.text;
                      final success = widget.ref
                          .read(progressRepositoryProvider)
                          .unlockSkins(code);
                      if (success) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.unlockSuccess),
                          ),
                        );
                      } else {
                        setState(() {
                          _errorMessage = l10n.unlockErrorInvalid;
                        });
                      }
                    },
                    child: Text(
                      l10n.unlockNow,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
