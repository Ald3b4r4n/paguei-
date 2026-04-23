import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CameraPermissionExplainer extends StatelessWidget {
  const CameraPermissionExplainer({
    super.key,
    required this.onAllowPressed,
    required this.onDenyPressed,
    this.isPermanentlyDenied = false,
    this.onOpenSettingsPressed,
  });

  final VoidCallback onAllowPressed;
  final VoidCallback onDenyPressed;
  final bool isPermanentlyDenied;
  final VoidCallback? onOpenSettingsPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Icon(
                Icons.camera_alt_outlined,
                size: 80,
                color: cs.primary,
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.8, 0.8)),
              const SizedBox(height: 32),
              Text(
                'Acesso à câmera',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              )
                  .animate(delay: 150.ms)
                  .fadeIn(duration: 350.ms)
                  .slideY(begin: 0.1, end: 0),
              const SizedBox(height: 16),
              Text(
                isPermanentlyDenied
                    ? 'O acesso à câmera foi bloqueado. Abra as configurações do sistema para permitir.'
                    : 'Para escanear boletos diretamente com a câmera, o Paguei? precisa de permissão de acesso.\n\nSeus dados ficam apenas no seu dispositivo.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ).animate(delay: 250.ms).fadeIn(duration: 350.ms),
              const SizedBox(height: 16),
              _PrivacyNote(color: cs.primary),
              const Spacer(),
              if (isPermanentlyDenied) ...[
                FilledButton.icon(
                  onPressed: onOpenSettingsPressed,
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Abrir Configurações'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onDenyPressed,
                  child: const Text('Usar importação de arquivo'),
                ),
              ] else ...[
                FilledButton.icon(
                  onPressed: onAllowPressed,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Permitir acesso à câmera'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onDenyPressed,
                  child: const Text('Usar importação de arquivo'),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Câmera usada apenas durante o scan. Nenhuma imagem é salva ou enviada.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
