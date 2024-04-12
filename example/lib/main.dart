import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:markdown/markdown.dart' as md;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:webview_windows/webview_windows.dart';
import 'package:window_manager/window_manager.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // For full-screen example
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  
  windowManager.setSize(Size(1600, 1000), animate: true);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, navigatorKey: navigatorKey, home: ExampleBrowser());
  }
}

class ExampleBrowser extends StatefulWidget {
  @override
  State<ExampleBrowser> createState() => _ExampleBrowser();
}

class _ExampleBrowser extends State<ExampleBrowser> {
  Future<String> _loadUrl() async {
      final baseUrl = "https://api.curseforge.com";
  Map<String, String> userHeader = {
    "Content-type": "application/json",
    "Accept": "application/json",
    "x-api-key":
        "\$2a\$10\$zApu4/n/e1nylJMTZMv5deblPpAWUHXc226sEIP1vxCjlYQoQG3QW",
  };
 final res = await http.get(Uri.parse('$baseUrl/v1/mods/643605/description'),
     headers: userHeader);
    final hit = jsonDecode(utf8.decode(res.bodyBytes));
    return hit["data"];

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FutureBuilder(
            future: _loadUrl(),
            builder: (context, snapshot) => snapshot.hasData
                ? WebviewWidget(
                    cachHTMLFile: File(
                        "C:\\Users\\joshi\\Documents\\GitHub\\flutter-webview-windows\\example\\lib\\html\\index.html"),
                    body: snapshot.data as String,
                  )
                : Container()),
      ),
    );
  }



}
