import 'package:flutter/material.dart';
import 'social_api.dart';

class MemberGrid extends StatelessWidget {
  const MemberGrid({
    super.key,
    required this.users,
    required this.selected,
    required this.onToggle,
    this.token = '',
    this.shrinkWrap = false,
    this.enabled = true,
  });
  final List<Json> users;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final String token;
  final bool shrinkWrap, enabled;
  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: shrinkWrap,
    physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      mainAxisExtent: 116,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
    ),
    itemCount: users.length,
    itemBuilder: (context, index) {
      final user = users[index], id = '${users[index]['id']}';
      final avatar = '${user['avatar'] ?? ''}';
      return Semantics(
        selected: selected.contains(id),
        button: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: enabled ? () => onToggle(id) : null,
          child: Column(
            children: [
              const SizedBox(height: 4),
              SizedBox(
                width: 68,
                height: 68,
                child: Stack(
                  children: [
                    ClipOval(
                      child: avatar.isEmpty
                          ? const SizedBox(
                              width: 68,
                              height: 68,
                              child: Icon(Icons.person_outline, size: 36),
                            )
                          : Image.network(
                              Uri.parse(
                                SocialApi.base,
                              ).resolve(avatar).toString(),
                              headers: {
                                if (token.isNotEmpty &&
                                    Uri.parse(
                                          SocialApi.base,
                                        ).resolve(avatar).origin ==
                                        Uri.parse(SocialApi.base).origin)
                                  'Authorization': 'Bearer $token',
                              },
                              width: 68,
                              height: 68,
                              fit: BoxFit.cover,
                              errorBuilder: (_, e, s) => const SizedBox(
                                width: 68,
                                height: 68,
                                child: Icon(Icons.person_outline, size: 36),
                              ),
                            ),
                    ),
                    if (selected.contains(id))
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Icon(
                          Icons.check_circle,
                          size: 22,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${user['username'] ?? user['name'] ?? ''}',
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      );
    },
  );
}
