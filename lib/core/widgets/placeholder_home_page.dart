import 'package:flutter/material.dart';

/// Temporary stand-in for the real pricelist home screen (step 3 of the
/// rewrite plan). Only exists so the skeleton has a reachable route to
/// verify the app boots and the router works end-to-end.
class PlaceholderHomePage extends StatelessWidget {
  const PlaceholderHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alita Pricelist')),
      body: const Center(
        child: Text('Skeleton OK — fitur belum diimplementasikan.'),
      ),
    );
  }
}
