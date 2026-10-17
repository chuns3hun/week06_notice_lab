import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const NoticeApp());
}

class NoticeApp extends StatelessWidget {
  const NoticeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '공지사항 앱',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const NoticeScreen(),
    );
  }
}

enum NoticeState { initial, loading, success, failure }

class NoticeScreen extends StatefulWidget {
  const NoticeScreen({super.key});

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  NoticeState _state = NoticeState.initial;
  String _noticeMessage = '';
  String _errorMessage = '';
  int _requestCount = 0;

  // 모의 서비스: 네트워크 요청 가상 처리
  Future<String> fetchNoticeMock() async {
    await Future.delayed(const Duration(seconds: 2));
    final random = Random();
    if (random.nextBool()) {
      return "Notice: [중요] 시스템 점검 안내 (10월 20일 00:00~06:00)";
    } else {
      throw Exception("네트워크 연결 실패 (서버 응답 없음)");
    }
  }

  Future<void> _loadNotice() async {
    // 중복 클릭 방지 (AC4)
    if (_state == NoticeState.loading) return;

    setState(() {
      _state = NoticeState.loading;
      _requestCount++;
      _errorMessage = '';
    });

    try {
      final result = await fetchNoticeMock();
      setState(() {
        _state = NoticeState.success;
        _noticeMessage = result;
      });
    } catch (e) {
      setState(() {
        _state = NoticeState.failure;
        _errorMessage = e.toString().replaceAll("Exception: ", "");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("공지사항")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("총 요청 횟수: $_requestCount회", style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 20),
              _buildContent(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _state == NoticeState.loading ? null : _loadNotice,
                child: Text(_state == NoticeState.failure ? "재시도" : "공지사항 불러오기"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case NoticeState.initial:
        return const Text("버튼을 눌러 공지를 확인하세요.");
      case NoticeState.loading:
        return const CircularProgressIndicator();
      case NoticeState.success:
        return Text(
          _noticeMessage,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        );
      case NoticeState.failure:
        return Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            Text(_errorMessage, style: const TextStyle(color: Colors.red)),
          ],
        );
    }
  }
}