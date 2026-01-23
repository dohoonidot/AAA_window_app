import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart';

/// AgendaAI 웹뷰 화면
class AgendaAIWebViewScreen extends StatefulWidget {
  const AgendaAIWebViewScreen({super.key});

  static const String webUrl = 'https://meetingai.co.kr/';

  @override
  State<AgendaAIWebViewScreen> createState() => _AgendaAIWebViewScreenState();
}

class _AgendaAIWebViewScreenState extends State<AgendaAIWebViewScreen> {
  final _controller = WebviewController();
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initializeWebView() async {
    try {
      await _controller.initialize();

      // 캐시 클리어
      await _controller.clearCache();

      _controller.url.listen((url) {
        // URL 변경 시 처리
      });

      _controller.loadingState.listen((LoadingState state) {
        setState(() {
          isLoading = state == LoadingState.loading;
        });
      });

      await _controller.loadUrl(AgendaAIWebViewScreen.webUrl);
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = '웹뷰 초기화 실패: $e';
      });
    }
  }

  void _reload() {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: '뒤로가기',
        ),
        title: const Text(
          'AgendaAI',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 1,
        shadowColor: Colors.black26,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Colors.black87,
            ),
            onPressed: _reload,
            tooltip: '새로고침',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: errorMessage != null
          ? _buildErrorWidget()
          : Stack(
              children: [
                // WebView
                Positioned.fill(
                  child: Webview(_controller),
                ),

                // 로딩 인디케이터
                if (isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.white,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Color(0xFF4A6CF7),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'AgendaAI 페이지를 불러오는 중...',
                              style: TextStyle(
                                color: Color(0xFF6C757D),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  /// 오류 화면 위젯
  Widget _buildErrorWidget() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              '페이지 로드 실패',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                errorMessage ?? '알 수 없는 오류가 발생했습니다.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF6C757D),
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A6CF7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
