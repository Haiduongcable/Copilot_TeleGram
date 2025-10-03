import 'package:flutter/material.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.radius = 20,
    this.statusColor,
  });

  final String? imageUrl;
  final String? initials;
  final double radius;
  final Color? statusColor;

  @override
  Widget build(BuildContext context) {
    final child = imageUrl != null
        ? ClipOval(
            child: Image.network(
              imageUrl!,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _Initials(radius: radius, initials: initials),
            ),
          )
        : _Initials(radius: radius, initials: initials);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (statusColor != null)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: radius * 0.6,
              height: radius * 0.6,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.radius, this.initials});

  final double radius;
  final String? initials;

  @override
  Widget build(BuildContext context) {
    final source = (initials ?? '?').trim();
    final display = source.isEmpty
        ? '?'
        : source.substring(0, source.length >= 2 ? 2 : 1);
    return CircleAvatar(
      radius: radius,
      child: Text(display.toUpperCase()),
    );
  }
}
