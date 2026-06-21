import 'package:flutter/material.dart';

import 'package:bt_mobile/app/app.dart';
import 'package:bt_mobile/config/app_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    AppConfig.devSandbox
        ? MaterialApp(home: Home())
        : const BrowntapeApp(),
  );
}

/// Tutorial-style screen for hot reload practice.
/// Edit this class, wait for autosave (~1s), and the emulator updates.
class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('my first app'),
        centerTitle: true,
        backgroundColor: Colors.red[600],
      ),
      body: Center(
        child: IconButton(
          onPressed: () {
            debugPrint('you clicked me');
          },
          icon: const Icon(Icons.alternate_email),
          color: Colors.amber,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red[600],
        onPressed: () {},
        child: const Text('click'),
      ),
    );
  }
}
