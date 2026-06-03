import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    home: KanColleApp(),
    themeMode: ThemeMode.dark,
    darkTheme: ThemeData.dark(),
  ));
}

class KanColleApp extends StatefulWidget {
  const KanColleApp({Key? key}) : super(key: key);
  @override
  _KanColleAppState createState() => _KanColleAppState();
}

class _KanColleAppState extends State<KanColleApp> {
  final List<String> apiLog = [];
  InAppWebViewController? webViewController;

  // API傍受用JavaScriptの注入設定
  InAppWebViewSettings get _webViewSettings => InAppWebViewSettings(
    useShouldInterceptAjaxRequest: true,
    javaScriptEnabled: true,
    userAgent:
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
        'AppleWebKit/605.1.15 (KHTML, like Gecko) '
        'Version/17.0 Safari/605.1.15',
  );

  // DMM地域制限回避 + ビューポート最適化スクリプト
  final _initScript = WKUserScript(
    source: '''
      document.cookie='ckcy=1;expires=Sun,04 Feb 2029 09:00:09 GMT;'
               + 'path=/netgame;domain=.dmm.com';
      var meta = document.createElement('meta');
      meta.name = 'viewport';
      var scale = (window.innerWidth / 1200).toString();
      meta.content = 'width=1200,initial-scale=' + scale
                   + ',maximum-scale=' + scale + ',user-scalable=no';
      document.getElementsByTagName('head')[0].appendChild(meta);
    ''',
    injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
    forMainFrameOnly: false,
  );

  void _addLog(String message) {
    setState(() {
      apiLog.insert(0, message); // 新しいログを先頭に追加
      if (apiLog.length > 200) apiLog.removeLast(); // 上限200件
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── 上半分: 艦これWebView ──────────────────
            Expanded(
              flex: 1,
              child: InAppWebView(
                initialUrlRequest: URLRequest(
                  url: WebUri(
                    'https://www.dmm.com/netgame/social/-/gadgets/=/app_id=854854/',
                  ),
                ),
                initialSettings: _webViewSettings,
                initialUserScripts: UnmodifiableListView([_initScript]),
                onWebViewCreated: (controller) {
                  webViewController = controller;
                },
                // kcsapi通信を傍受
                shouldInterceptAjaxRequest: (controller, request) async {
                  return request;
                },
                onAjaxReadyStateChange: (controller, request) async {
                  if (request.readyState == AjaxRequestReadyState.DONE &&
                      request.status == 200 &&
                      (request.url?.toString().contains('kcsapi') ?? false)) {
                    _addLog('傍受: ${request.url}');
                    // TODO: ここでresponseTextをパースして
                    //       大破判定・任務カウント・遠征確認を行う
                  }
                  return AjaxRequestAction.PROCEED;
                },
                onLoadStop: (controller, url) async {
                  _addLog('ページ読込完了: $url');
                },
              ),
            ),

            const Divider(height: 1, thickness: 1),

            // ── 下半分: 補助タブ ──────────────────────
            Expanded(
              flex: 1,
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    // タブバー
                    const TabBar(
                      tabs: [
                        Tab(icon: Icon(Icons.list_alt), text: 'APIログ'),
                        Tab(icon: Icon(Icons.directions_boat), text: '艦隊状況'),
                        Tab(icon: Icon(Icons.language), text: 'ブラウザ'),
                      ],
                    ),
                    // タブコンテンツ
                    Expanded(
                      child: TabBarView(
                        children: [
                          // タブ1: APIログ
                          apiLog.isEmpty
                              ? const Center(child: Text('通信待機中...'))
                              : ListView.builder(
                                  itemCount: apiLog.length,
                                  itemBuilder: (context, index) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    child: Text(
                                      apiLog[index],
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontFamily: 'monospace'),
                                    ),
                                  ),
                                ),

                          // タブ2: 艦隊状況（今後実装）
                          const Center(
                            child: Text(
                              '艦隊状況\n（API傍受後に実装）',
                              textAlign: TextAlign.center,
                            ),
                          ),

                          // タブ3: サブブラウザ（Wiki等）
                          InAppWebView(
                            initialUrlRequest: URLRequest(
                              url: WebUri('https://wikiwiki.jp/kancolle/'),
                            ),
                            initialSettings: InAppWebViewSettings(
                              javaScriptEnabled: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}