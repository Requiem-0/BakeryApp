import 'package:flutter/material.dart';

class ServiceIcon extends StatelessWidget {
  final dynamic icon; // Can be a String (emoji) or IconData
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final double iconSize;
  final double borderRadius;

  const ServiceIcon({
    super.key,
    required this.icon,
    this.backgroundColor,
    this.iconColor,
    this.size = 42,
    this.iconSize = 18,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).dividerColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: icon is String
          ? Text(icon as String, style: TextStyle(fontSize: iconSize))
          : Icon(icon as IconData, color: iconColor, size: iconSize),
    );
  }
}
