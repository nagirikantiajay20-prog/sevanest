import 'package:flutter/material.dart';

/// Temporary body for routes whose module is not built yet. Delete usages as each module lands.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen(this.title, {super.key});

  final String title; // placeholder only; real screens use AppLocalizations

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title — not built yet')),
    );
  }
}
