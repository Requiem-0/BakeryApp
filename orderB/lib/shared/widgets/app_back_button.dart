import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;

  const AppBackButton({super.key, this.onPressed, this.color});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed ?? () => context.pop(),
      style: IconButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      icon: Icon(Icons.chevron_left_rounded,
          size: 28, color: color ?? Theme.of(context).colorScheme.onSurface),
    );
  }
}
