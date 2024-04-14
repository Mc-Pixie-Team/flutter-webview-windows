import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../webview_windows.dart';
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

final navigatorKey = GlobalKey<NavigatorState>();

class WebviewWidget extends StatefulWidget {
  String body;
  File cachHTMLFile;
  Function(PointerScrollEvent)? onscroll;
  WebviewWidget({Key? key, required this.body, required this.cachHTMLFile, this.onscroll})
      : super(key: key);

  @override
  _WebviewWidgetState createState() => _WebviewWidgetState();
}

class _WebviewWidgetState extends State<WebviewWidget>
  {
  final _controller = WebviewController();
  final _textController = TextEditingController();
  final List<StreamSubscription> _subscriptions = [];
  double _scrollgl = 100.0;
  @override
  void initState() {
    super.initState();
    
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    // Optionally initialize the webview environment using
    // a custom user data directory
    // and/or a custom browser executable directory
    // and/or custom chromium command line flags
    //await WebviewController.initializeEnvironment(
    //    additionalArguments: '--show-fps-counter');

    dom.Document docs = html.parse(await widget.cachHTMLFile.readAsString());

    docs.body!.innerHtml = md.markdownToHtml(widget.body);
    for (var i in docs.body!.getElementsByTagName("a")) {
      String? attribut = i.attributes["href"];
      if (attribut == null) return;

      if (attribut.startsWith("/linkout?")) {
        // If the URL was double-encoded, you may need to decode it again
        String fullyDecoded =
            Uri.decodeComponent(Uri.decodeComponent(attribut));
        fullyDecoded = fullyDecoded.replaceAll("/linkout?remoteUrl=", "");

        i.attributes["href"] = fullyDecoded;
      }
    }

    widget.cachHTMLFile.writeAsStringSync(docs.outerHtml);

    try {
      await _controller.initialize();
      _subscriptions.add(_controller.url.listen((url) {
        _textController.text = url;
      }));

      _subscriptions
          .add(_controller.containsFullScreenElementChanged.listen((flag) {
        debugPrint('Contains fullscreen element: $flag');
        // windowManager.setFullScreen(flag);
      }));

      await _controller.setBackgroundColor(Colors.transparent);
      await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.allow);

      await _controller.loadUrl(widget.cachHTMLFile.path);

      if (!mounted) return;
 

      setState(() {});
    } on PlatformException catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
            context: context,
            builder: (_) => AlertDialog(
                  title: Text('Error'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Code: ${e.code}'),
                      Text('Message: ${e.message}'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      child: Text('Continue'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    )
                  ],
                ));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Text(
        'Initializing content',
        style: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.w500,
        ),
      );
    } else {
      return
       
       Container(
          width: double.infinity,
          height: double.infinity,
          child: Webview(
            _controller,
            onscroll: widget.onscroll,
            permissionRequested: _onPermissionRequested,
          ),
        );
         
  
    }
  }

  Future<WebviewPermissionDecision> _onPermissionRequested(
      String url, WebviewPermissionKind kind, bool isUserInitiated) async {
    final decision = await showDialog<WebviewPermissionDecision>(
      context: navigatorKey.currentContext!,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('WebView permission requested'),
        content: Text('WebView has requested permission \'$kind\''),
        actions: <Widget>[
          TextButton(
            onPressed: () =>
                Navigator.pop(context, WebviewPermissionDecision.deny),
            child: const Text('Deny'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, WebviewPermissionDecision.allow),
            child: const Text('Allow'),
          ),
        ],
      ),
    );

    return decision ?? WebviewPermissionDecision.none;
  }

  @override
  void dispose() {
    _subscriptions.forEach((s) => s.cancel());
    _controller.dispose();
    super.dispose();
  }
}
