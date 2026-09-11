import 'package:flutter/material.dart';
import 'package:sornaz/screens/Authentication/ui/pages/authentication.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';

class JoinCommunity extends StatelessWidget {
  const JoinCommunity({super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.account_circle_outlined, size: 72),
        const SizedBox(height: 16),
        Text(
          socialText(
            context,
            'به جامعه سُرناز بپیوندید',
            'Join the Sornaz community',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => socialPush(context, const SignInScreen()),
          child: Text(
            socialText(context, 'ورود یا ثبت‌نام', 'Sign in or register'),
          ),
        ),
      ],
    ),
  );
}
