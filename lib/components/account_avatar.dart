import 'package:flutter/material.dart';
import 'package:sornaz/screens/Social/social_api.dart';

class AccountAvatar extends StatelessWidget {
  const AccountAvatar({super.key, this.avatar, this.token, this.size = 40});
  final String? avatar, token;
  final double size;
  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final base = Uri.parse(SocialApi.base);
    final uri = Uri.parse(
      base.origin + '/',
    ).resolve(value.replaceAll('\\', '/'));
    return ['http', 'https'].contains(uri.scheme) && uri.origin == base.origin
        ? uri.toString()
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final source = url(avatar);
    final fallback = Icon(
      Icons.account_circle,
      size: size,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return ClipOval(
      child: source == null
          ? fallback
          : Image.network(
              source,
              width: size,
              height: size,
              fit: BoxFit.cover,
              headers: token?.isNotEmpty == true
                  ? {'Authorization': 'Bearer $token'}
                  : null,
              errorBuilder: (_, _, _) => fallback,
            ),
    );
  }
}
