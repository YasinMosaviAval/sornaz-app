import 'package:flutter/material.dart';
import 'app_text.dart';

class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({
    super.key,
    this.centered = true,
    this.size = 24,
    this.label,
  });
  final bool centered;
  final double size;
  final String? label;
  @override
  Widget build(BuildContext context) {
    final indicator = SizedBox.square(
      dimension: size,
      child: CircularProgressIndicator(strokeWidth: 2, semanticsLabel: label),
    );
    return centered ? Center(child: indicator) : indicator;
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.onRetry,
    this.retryLabel,
    this.iconColor,
  });
  final String message;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onRetry;
  final String? retryLabel;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: iconColor ?? theme.colorScheme.primary),
            const SizedBox(height: 16),
            AppText(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: AppText(
                  retryLabel ??
                      (Localizations.localeOf(context).languageCode == 'fa'
                          ? 'تلاش دوباره'
                          : 'Retry'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel,
  });
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;
  @override
  Widget build(BuildContext context) => AppEmptyState(
    message: message,
    icon: Icons.error_outline,
    iconColor: Theme.of(context).colorScheme.error,
    onRetry: onRetry,
    retryLabel: retryLabel,
  );
}
