import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import './primary_button.dart';

class BrowseMenuButton extends StatelessWidget {
  final VoidCallback? onTap;

  const BrowseMenuButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: 'Browse',
      onTap: onTap ?? () => context.go('/home'),
    );
  }
}
