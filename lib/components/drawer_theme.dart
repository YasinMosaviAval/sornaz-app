import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_data.dart';

class DrawerThemeScope extends StatelessWidget {
  const DrawerThemeScope({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final theme = ThemeData(
      brightness: data.isDark ? Brightness.dark : Brightness.light,
      fontFamily: data.fontFamily,
      colorSchemeSeed: data.isDark
          ? const Color(0xffbfa02a)
          : const Color(0xff3478ff),
    );
    return Theme(
      data: theme.copyWith(
        textTheme: TextTheme(
          displayLarge: theme.textTheme.displayLarge?.copyWith(
            fontSize:
                (theme.textTheme.displayLarge?.fontSize ?? 14) + data.fontSize,
          ),
          displayMedium: theme.textTheme.displayMedium?.copyWith(
            fontSize:
                (theme.textTheme.displayMedium?.fontSize ?? 14) + data.fontSize,
          ),
          displaySmall: theme.textTheme.displaySmall?.copyWith(
            fontSize:
                (theme.textTheme.displaySmall?.fontSize ?? 14) + data.fontSize,
          ),
          headlineLarge: theme.textTheme.headlineLarge?.copyWith(
            fontSize:
                (theme.textTheme.headlineLarge?.fontSize ?? 14) + data.fontSize,
          ),
          headlineMedium: theme.textTheme.headlineMedium?.copyWith(
            fontSize:
                (theme.textTheme.headlineMedium?.fontSize ?? 14) +
                data.fontSize,
          ),
          headlineSmall: theme.textTheme.headlineSmall?.copyWith(
            fontSize:
                (theme.textTheme.headlineSmall?.fontSize ?? 14) + data.fontSize,
          ),
          titleLarge: theme.textTheme.titleLarge?.copyWith(
            fontSize:
                (theme.textTheme.titleLarge?.fontSize ?? 14) + data.fontSize,
          ),
          titleMedium: theme.textTheme.titleMedium?.copyWith(
            fontSize:
                (theme.textTheme.titleMedium?.fontSize ?? 14) + data.fontSize,
          ),
          titleSmall: theme.textTheme.titleSmall?.copyWith(
            fontSize:
                (theme.textTheme.titleSmall?.fontSize ?? 14) + data.fontSize,
          ),
          bodyLarge: theme.textTheme.bodyLarge?.copyWith(
            fontSize:
                (theme.textTheme.bodyLarge?.fontSize ?? 14) + data.fontSize,
          ),
          bodyMedium: theme.textTheme.bodyMedium?.copyWith(
            fontSize:
                (theme.textTheme.bodyMedium?.fontSize ?? 14) + data.fontSize,
          ),
          bodySmall: theme.textTheme.bodySmall?.copyWith(
            fontSize:
                (theme.textTheme.bodySmall?.fontSize ?? 14) + data.fontSize,
          ),
          labelLarge: theme.textTheme.labelLarge?.copyWith(
            fontSize:
                (theme.textTheme.labelLarge?.fontSize ?? 14) + data.fontSize,
          ),
          labelMedium: theme.textTheme.labelMedium?.copyWith(
            fontSize:
                (theme.textTheme.labelMedium?.fontSize ?? 14) + data.fontSize,
          ),
          labelSmall: theme.textTheme.labelSmall?.copyWith(
            fontSize:
                (theme.textTheme.labelSmall?.fontSize ?? 14) + data.fontSize,
          ),
        ),
      ),
      child: child,
    );
  }
}
