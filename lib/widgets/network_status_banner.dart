import 'package:flutter/material.dart';

class NetworkStatusBanner extends StatelessWidget {
  final Widget child;

  const NetworkStatusBanner({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Simply return the child widget without any network checking for now
    // TODO: Implement actual network checking when backend is ready
    return child;
  }
}
