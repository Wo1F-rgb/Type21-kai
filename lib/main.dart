import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: KanColleApp(), themeMode: ThemeMode.dark));
}

class KanColleApp extends StatefulWidget {
  const KanColleApp({Key? key}) : super(key: key);
  @override
  _KanColleAppState createState() => _KanColleAppState();
}

class _KanColleAppState extends State<KanColleApp> {
  String apiLog = "通信待機中...\n(DMMにログインして出撃等を行うとAPIを傍受します)\n";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 100,
              child: Text(apiLog),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Add your tab content here
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}