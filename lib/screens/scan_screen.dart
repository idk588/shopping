import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanScreen extends StatefulWidget {
  final String title;

  const ScanScreen({super.key, required this.title});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _busy = false; // debounce so it doesn't fire repeatedly

  void _emit(String value) async {
    if (_busy) return;
    _busy = true;

    // Return the scanned value to the previous screen
    Navigator.pop(context, value);

    // If you later switch to multi-scan, remove pop() and use callbacks.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: MobileScanner(
        onDetect: (capture) {
          final codes = capture.barcodes;
          if (codes.isEmpty) return;

          final raw = codes.first.rawValue;
          if (raw == null || raw.isEmpty) return;

          _emit(raw);
        },
      ),
    );
  }
}
