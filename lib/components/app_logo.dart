import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_images.dart';

/// All supplied brand assets are square; keep layout and image aspect ratios identical.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 40,
    this.withBackground = false,
    this.isDark,
  });
  final double size;
  final bool withBackground;
  final bool? isDark;
  @override
  Widget build(BuildContext context) {
    final dark = isDark ?? context.watch<AppData>().isDark;
    final asset = withBackground
        ? (dark
              ? AppImages.logo_dark_background
              : AppImages.logo_light_background)
        : (dark ? AppImages.logo_dark : AppImages.logo_light);
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: 'Sornaz',
      filterQuality: FilterQuality.medium,
    );
  }
}
