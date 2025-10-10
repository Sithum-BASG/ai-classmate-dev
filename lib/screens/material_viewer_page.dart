import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

class MaterialViewerPage extends StatelessWidget {
  final String title;
  final String url;
  const MaterialViewerPage({super.key, required this.title, required this.url});

  bool _isImage(String name) {
    final n = name.toLowerCase();
    return n.endsWith('.jpg') ||
        n.endsWith('.jpeg') ||
        n.endsWith('.png') ||
        n.endsWith('.webp') ||
        n.endsWith('.gif');
  }

  @override
  Widget build(BuildContext context) {
    final bool showAsImage = _isImage(title);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: showAsImage
            ? InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                ),
              )
            : _DocFallback(url: url),
      ),
    );
  }
}

class _DocFallback extends StatelessWidget {
  final String url;
  const _DocFallback({required this.url});

  @override
  Widget build(BuildContext context) {
    final docsUrl = Uri.parse(
        'https://docs.google.com/viewer?embedded=true&url=${Uri.encodeComponent(url)}');
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Preview not available in-app. Open in viewer?',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
        FilledButton(
          onPressed: () async {
            await launcher.launchUrl(docsUrl,
                mode: launcher.LaunchMode.externalApplication);
          },
          child: const Text('Open in Viewer'),
        ),
      ],
    );
  }
}


